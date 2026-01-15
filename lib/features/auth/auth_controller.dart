import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/models/user_model.dart';
import '../../core/models/shop_model.dart';

/// Authentication state
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Auth controller provider
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController();
  },
);

/// Stream provider for auth state changes
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provider for current user model
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(firebaseUser.uid)
      .get();

  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});

/// Authentication controller
class AuthController extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthController() : super(const AuthInitial()) {
    _init();
  }

  /// Initialize auth state
  Future<void> _init() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUser(user.uid);
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// Load user from Firestore
  Future<void> _loadUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final userModel = UserModel.fromFirestore(doc);
        state = AuthAuthenticated(userModel);
      } else {
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthError('Failed to load user: $e');
    }
  }

  /// Sign in with Google
  ///
  /// Flow:
  /// 1. User signs in with Google
  /// 2. Check if users/{uid} exists in Firestore
  /// 3. If new: Create basic doc with role: 'user', shopStatus: 'none'
  /// 4. Always redirect to /home
  Future<bool> signInWithGoogle() async {
    try {
      state = const AuthLoading();

      // Start Google Sign In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        state = const AuthUnauthenticated();
        return false;
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        state = const AuthError('Failed to sign in');
        return false;
      }

      return await _handlePostSignIn(firebaseUser);
    } catch (e) {
      state = AuthError('Sign in failed: $e');
      return false;
    }
  }

  /// Sign in with Email and Password
  /// For users who have set up a password through their profile
  Future<({bool success, String? error})> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      state = const AuthLoading();

      if (email.isEmpty || password.isEmpty) {
        state = const AuthUnauthenticated();
        return (success: false, error: 'Email and password are required');
      }

      // Sign in with email/password
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        state = const AuthError('Failed to sign in');
        return (success: false, error: 'Failed to sign in');
      }

      // Load user from Firestore (user must already exist from Google sign-in)
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        state = const AuthUnauthenticated();
        return (
          success: false,
          error: 'Account not found. Please sign up with Google first.',
        );
      }

      final userModel = UserModel.fromFirestore(userDoc);
      state = AuthAuthenticated(userModel);
      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      state = const AuthUnauthenticated();
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        default:
          errorMessage = e.message ?? 'Failed to sign in';
      }
      return (success: false, error: errorMessage);
    } catch (e) {
      state = const AuthUnauthenticated();
      return (success: false, error: 'Sign in failed: $e');
    }
  }

  /// Handle Phone Login (Restricted to Admin/Shop & Existing Users)
  Future<bool> handlePhoneLogin(User firebaseUser) async {
    try {
      state = const AuthLoading();

      // Strict Check: User must exist in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // New User trying to login via Phone -> Block
        await _auth.signOut();
        state = const AuthError('Please sign up with Google first.');
        return false;
      }

      final userModel = UserModel.fromFirestore(userDoc);

      // Strict Check: Role must be Admin or Shop
      if (userModel.role == UserRole.user) {
        await _auth.signOut();
        state = const AuthError(
          'Phone login is restricted to Admin & Shop accounts.',
        );
        return false;
      }

      state = AuthAuthenticated(userModel);
      return true;
    } catch (e) {
      state = AuthError('Login failed: $e');
      return false;
    }
  }

  /// Internal Method to sync user data (Used by Google Sign In)
  Future<bool> _handlePostSignIn(User firebaseUser) async {
    try {
      // Check if user exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      UserModel userModel;

      if (!userDoc.exists) {
        // New user - create document (Only allowed via Google)
        userModel = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName:
              firebaseUser.displayName ?? firebaseUser.phoneNumber ?? 'User',
          photoUrl: firebaseUser.photoURL,
          role: UserRole.user,
          shopStatus: ShopStatus.none,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          contactNumbers: firebaseUser.phoneNumber != null
              ? [
                  {
                    'number': firebaseUser.phoneNumber,
                    'type': 'primary',
                    'verified': true,
                  },
                ]
              : [],
          isVerified: true, // Auto-verify all users
        );

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userModel.toFirestore());
      } else {
        // Existing user - load from Firestore
        userModel = UserModel.fromFirestore(userDoc);

        // Ensure legacy users are also verified
        if (!userModel.isVerified) {
          await _firestore.collection('users').doc(firebaseUser.uid).update({
            'isVerified': true,
          });
          userModel = userModel.copyWith(isVerified: true);
        }
      }

      state = AuthAuthenticated(userModel);
      return true;
    } catch (e) {
      state = AuthError('Failed to sync user data: $e');
      return false;
    }
  }

  /// Sign in with Google for Web/Desktop (using signInWithPopup)
  /// This is specifically for Web/Windows platform where GoogleSignIn plugin doesn't work well
  Future<bool> signInWithGooglePopup() async {
    try {
      state = const AuthLoading();

      // Create Google Auth Provider
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // Sign in with popup (Web only)
      final userCredential = await _auth.signInWithPopup(googleProvider);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        state = const AuthError('Failed to sign in with Google');
        return false;
      }

      return await _handlePostSignIn(firebaseUser);
    } catch (e) {
      state = AuthError('Google Sign in failed: $e');
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Sign out failed: $e');
    }
  }

  /// Refresh current user
  Future<void> refreshUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _loadUser(user.uid);
    }
  }

  /// Submit shop application
  Future<bool> submitShopApplication({
    required String shopName,
    required String category,
    required String description,
    required List<Map<String, dynamic>> contactNumbers,
    String? gstId,
  }) async {
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) return false;

      final user = currentState.user;
      final uid = user.uid;

      // Create shop request
      final request = ShopRequest(
        uid: uid,
        shopName: shopName,
        category: category,
        description: description,
        gstId: gstId,
        timestamp: DateTime.now(),
        status: 'pending',
        contactNumbers: contactNumbers,
        userEmail: user.email,
        userName: user.displayName,
      );

      // Write to shop_requests collection
      await _firestore
          .collection('shop_requests')
          .doc(uid)
          .set(request.toFirestore());

      // Update user document with pending status
      await _firestore.collection('users').doc(uid).update({
        'shopStatus': ShopStatus.pending.name,
        'contactNumbers': contactNumbers,
        'updatedAt': Timestamp.now(),
      });

      // Update local state
      final updatedUser = user.copyWith(
        shopStatus: ShopStatus.pending,
        contactNumbers: contactNumbers,
        updatedAt: DateTime.now(),
      );
      state = AuthAuthenticated(updatedUser);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Approve shop request (Admin only)
  Future<bool> approveShopRequest(String uid) async {
    try {
      // Update user document
      await _firestore.collection('users').doc(uid).update({
        'role': UserRole.shop.name,
        'shopStatus': ShopStatus.approved.name,
        'updatedAt': Timestamp.now(),
      });

      // Get shop request data and update user with shop details
      final requestDoc = await _firestore
          .collection('shop_requests')
          .doc(uid)
          .get();
      if (requestDoc.exists) {
        final data = requestDoc.data()!;

        // 1. Create Shop Document in 'shops' collection
        final shop = ShopModel(
          id: uid, // Linking Shop ID to User UID for 1:1 relationship
          ownerId: uid,
          ownerEmail: data['userEmail'] ?? '',
          ownerName: data['userName'] ?? '',
          shopName: data['shopName'] ?? '',
          category: data['category'] ?? '',
          description: data['description'] ?? '',
          contactNumbers: List<Map<String, dynamic>>.from(
            data['contactNumbers'] ?? [],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isVerified: true, // Auto-verify since Admin approved
        );

        await _firestore.collection('shops').doc(uid).set(shop.toFirestore());

        // 2. Update User Document
        await _firestore.collection('users').doc(uid).update({
          'shopName': data['shopName'],
          'shopCategory': data['category'],
          'shopDescription': data['description'],
          'contactNumbers': data['contactNumbers'],
        });

        // 3. Update Request Status
        await _firestore.collection('shop_requests').doc(uid).update({
          'status': 'approved',
        });
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reject shop request (Admin only)
  Future<bool> rejectShopRequest(String uid) async {
    try {
      // Update user document
      await _firestore.collection('users').doc(uid).update({
        'shopStatus': ShopStatus.none.name,
        'updatedAt': Timestamp.now(),
      });

      // Update request status
      await _firestore.collection('shop_requests').doc(uid).update({
        'status': 'rejected',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add verified contact number to user profile
  Future<bool> addVerifiedContactNumber(String number) async {
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) return false;

      final user = currentState.user;
      final uid = user.uid;

      // Create new contact entry
      final newContact = {
        'number': number,
        'type': 'primary',
        'verified': true,
      };

      // Get existing contacts
      final currentContacts = List<Map<String, dynamic>>.from(
        user.contactNumbers,
      );

      // Remove existing primary if valid (keeping it simple for now, just append or replace)
      // If we want to enforce only one primary, we might want to clear others or just add.
      // Let's just append if not exists, or replace if exists.
      // Actually, for this simple requirement, we just ensuring they have a verified number.
      bool exists = false;
      for (var i = 0; i < currentContacts.length; i++) {
        if (currentContacts[i]['number'] == number) {
          currentContacts[i] = newContact; // Update verified status if matches
          exists = true;
          break;
        }
      }

      if (!exists) {
        currentContacts.add(newContact);
      }

      // Update Firestore
      await _firestore.collection('users').doc(uid).update({
        'contactNumbers': currentContacts,
        'updatedAt': Timestamp.now(),
        // We might also want to set isVerified to true if that's what "verified user" means generally?
        // The user model says "verified users can post". Maybe this phone verification should also toggle that?
        // Let's toggle isVerified too as it seems congruent with "compulsory for user to verify...".
        'isVerified': true,
      });

      // Update local state
      final updatedUser = user.copyWith(
        contactNumbers: currentContacts,
        isVerified: true,
        updatedAt: DateTime.now(),
      );
      state = AuthAuthenticated(updatedUser);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update user's nickname
  /// The nickname is used as the public display name across all services
  Future<bool> updateNickname(String nickname) async {
    try {
      final currentState = state;
      if (currentState is! AuthAuthenticated) return false;

      final user = currentState.user;
      final uid = user.uid;

      // Validate nickname
      final trimmedNickname = nickname.trim();
      if (trimmedNickname.isEmpty) {
        return false;
      }

      // Check for minimum length and valid characters
      if (trimmedNickname.length < 3 || trimmedNickname.length > 20) {
        return false;
      }

      // Update Firestore
      await _firestore.collection('users').doc(uid).update({
        'nickname': trimmedNickname,
        'updatedAt': Timestamp.now(),
      });

      // Update local state
      final updatedUser = user.copyWith(
        nickname: trimmedNickname,
        updatedAt: DateTime.now(),
      );
      state = AuthAuthenticated(updatedUser);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has password authentication linked
  bool hasPasswordLinked() {
    final user = _auth.currentUser;
    if (user == null) return false;

    return user.providerData.any(
      (provider) => provider.providerId == 'password',
    );
  }

  /// Set up password for existing Google account
  /// This links email/password provider to the Google account
  Future<({bool success, String? error})> setupPassword({
    required String password,
    required String confirmPassword,
  }) async {
    try {
      if (password != confirmPassword) {
        return (success: false, error: 'Passwords do not match');
      }

      if (password.length < 6) {
        return (
          success: false,
          error: 'Password must be at least 6 characters',
        );
      }

      final user = _auth.currentUser;
      if (user == null) {
        return (success: false, error: 'No user logged in');
      }

      if (user.email == null || user.email!.isEmpty) {
        return (success: false, error: 'No email associated with account');
      }

      // Check if password is already linked
      if (hasPasswordLinked()) {
        return (
          success: false,
          error: 'Password already set up. Use "Edit Password" instead.',
        );
      }

      // Create email/password credential
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // Link the credential to existing account
      await user.linkWithCredential(credential);

      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email already has a password. Try signing in.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Use at least 6 characters.';
          break;
        case 'provider-already-linked':
          errorMessage = 'Password already linked to this account.';
          break;
        case 'requires-recent-login':
          errorMessage =
              'Please sign out and sign in again before setting password.';
          break;
        default:
          errorMessage = e.message ?? 'Failed to set up password';
      }
      return (success: false, error: errorMessage);
    } catch (e) {
      return (success: false, error: 'Failed to set up password: $e');
    }
  }

  /// Update existing password
  /// Requires current password for verification
  Future<({bool success, String? error})> updatePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      if (newPassword != confirmPassword) {
        return (success: false, error: 'New passwords do not match');
      }

      if (newPassword.length < 6) {
        return (
          success: false,
          error: 'Password must be at least 6 characters',
        );
      }

      if (currentPassword == newPassword) {
        return (
          success: false,
          error: 'New password must be different from current password',
        );
      }

      final user = _auth.currentUser;
      if (user == null) {
        return (success: false, error: 'No user logged in');
      }

      if (user.email == null || user.email!.isEmpty) {
        return (success: false, error: 'No email associated with account');
      }

      // Re-authenticate with current password first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update to new password
      await user.updatePassword(newPassword);

      return (success: true, error: null);
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage =
              'Please sign out and sign in again before changing password';
          break;
        default:
          errorMessage = e.message ?? 'Failed to update password';
      }
      return (success: false, error: errorMessage);
    } catch (e) {
      return (success: false, error: 'Failed to update password: $e');
    }
  }
}

/// Provider for pending shop requests (Admin use)
final pendingShopRequestsProvider = StreamProvider<List<ShopRequest>>((ref) {
  return FirebaseFirestore.instance
      .collection('shop_requests')
      .where('status', isEqualTo: 'pending')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => ShopRequest.fromFirestore(doc)).toList(),
      );
});

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';

import '../../core/models/social_post_model.dart';
import '../../core/services/r2_storage_service.dart';

/// Firestore collection references
final _socialCollection = FirebaseFirestore.instance.collection('social');
final _commentsCollection = FirebaseFirestore.instance.collection(
  'social_comments',
);
final _usersCollection = FirebaseFirestore.instance.collection('users');

// ============================================
// PROVIDERS
// ============================================

/// R2 Storage Service Provider
final r2StorageProvider = Provider<R2StorageService>((ref) {
  return R2StorageService();
});

/// Stream provider for social feed posts
final socialFeedProvider = StreamProvider<List<SocialPost>>((ref) {
  return _socialCollection
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => SocialPost.fromFirestore(doc)).toList(),
      );
});

/// Provider to check if current user is verified
final isCurrentUserVerifiedProvider = FutureProvider<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  final doc = await _usersCollection.doc(user.uid).get();
  if (!doc.exists) return false;

  final data = doc.data();
  return data?['isVerified'] == true;
});

/// Current user info provider
final currentUserInfoProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    debugPrint('❌ currentUserInfoProvider: No user logged in');
    return null;
  }

  debugPrint('✅ currentUserInfoProvider: User found - ${user.uid}');

  try {
    final doc = await _usersCollection.doc(user.uid).get();

    if (doc.exists) {
      debugPrint('✅ Firestore user doc exists');
      return {
        'uid': user.uid,
        'displayName':
            doc.data()?['displayName'] ?? user.displayName ?? 'Anonymous',
        'photoUrl': doc.data()?['photoUrl'] ?? user.photoURL,
        'isVerified': doc.data()?['isVerified'] ?? false,
        'role': doc.data()?['role'] ?? 'user',
      };
    } else {
      // Firestore doc doesn't exist - use Firebase Auth data as fallback
      debugPrint('⚠️ Firestore user doc NOT found - using Firebase Auth data');
      return {
        'uid': user.uid,
        'displayName':
            user.displayName ?? user.email?.split('@').first ?? 'Anonymous',
        'photoUrl': user.photoURL,
        'isVerified': false,
      };
    }
  } catch (e) {
    debugPrint('❌ Error fetching user doc: $e');
    // Fallback to Firebase Auth data on error
    return {
      'uid': user.uid,
      'displayName': user.displayName ?? 'Anonymous',
      'photoUrl': user.photoURL,
      'isVerified': false,
    };
  }
});

/// Comments stream for a post
final postCommentsProvider = StreamProvider.family<List<PostComment>, String>((
  ref,
  postId,
) {
  return _commentsCollection
      .where('postId', isEqualTo: postId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => PostComment.fromFirestore(doc)).toList(),
      );
});

/// Upload state notifier
final uploadStateProvider =
    StateNotifierProvider<UploadStateNotifier, UploadState>((ref) {
      return UploadStateNotifier(ref);
    });

// ============================================
// UPLOAD STATE NOTIFIER
// ============================================

class UploadStateNotifier extends StateNotifier<UploadState> {
  final Ref _ref;

  UploadStateNotifier(this._ref) : super(const UploadState());

  /// Reset state
  void reset() {
    state = const UploadState();
  }

  /// Create a new post with media upload to R2
  Future<bool> createPost({
    required XFile file,
    required PostType type,
    String? caption,
  }) async {
    try {
      // Get current user
      final userInfo = await _ref.read(currentUserInfoProvider.future);
      if (userInfo == null) {
        state = state.copyWith(hasError: true, errorMessage: 'Not logged in');
        return false;
      }

      // Check if verified for posting - DISABLED: All users can post now
      // final isVerified = userInfo['isVerified'] ?? false;

      // Restrict Shop users from posting
      final userRoleString = userInfo['role'] ?? 'user';
      if (userRoleString == 'shop') {
        state = state.copyWith(
          hasError: true,
          errorMessage: 'Shops cannot post to social feed.',
        );
        return false;
      }

      // Read file bytes
      final bytes = await file.readAsBytes();
      final fileName = file.name;

      // Determine content type and folder
      String contentType;
      String folder;

      if (type == PostType.video) {
        contentType = 'video/mp4';
        folder = 'videos';
      } else {
        contentType = 'image/jpeg';
        folder = 'photos';
      }

      // Set initial state
      state = UploadState(totalBytes: bytes.length);

      debugPrint('📤 Starting R2 upload: $fileName ($contentType)');
      debugPrint('📦 File size: ${bytes.length} bytes');

      // Upload to R2
      final r2Service = _ref.read(r2StorageProvider);
      final result = await r2Service.uploadFile(
        fileBytes: bytes,
        fileName: fileName,
        folder: folder,
        contentType: contentType,
        onProgress: (progress, sent, total) {
          debugPrint(
            '📊 Upload progress: ${(progress * 100).toStringAsFixed(0)}%',
          );
          state = state.copyWith(
            progress: progress,
            bytesSent: sent,
            totalBytes: total,
          );
        },
      );

      if (!result.success) {
        debugPrint('❌ R2 Upload failed: ${result.error}');
        state = state.copyWith(
          hasError: true,
          errorMessage: result.error ?? 'Upload failed',
        );
        return false;
      }

      debugPrint('✅ R2 Upload successful: ${result.url}');

      // Create post document in Firestore
      final post = SocialPost(
        id: '', // Will be set by Firestore
        authorId: userInfo['uid'],
        authorName: userInfo['displayName'],
        authorPhotoUrl: userInfo['photoUrl'],
        type: type,
        mediaUrl: result.url,
        textContent: caption,
        aspectRatio: type == PostType.video ? 16 / 9 : 1.0, // Default ratios
        createdAt: DateTime.now(),
      );

      await _socialCollection.add(post.toFirestore());

      state = state.copyWith(
        isComplete: true,
        resultUrl: result.url,
        progress: 1.0,
      );

      return true;
    } catch (e) {
      debugPrint('Create post error: $e');
      state = state.copyWith(hasError: true, errorMessage: e.toString());
      return false;
    }
  }

  /// Create a text-only post
  Future<bool> createTextPost(String content) async {
    try {
      final userInfo = await _ref.read(currentUserInfoProvider.future);
      if (userInfo == null) {
        state = state.copyWith(hasError: true, errorMessage: 'Not logged in');
        return false;
      }

      // DISABLED: All users can post now
      // final isVerified = userInfo['isVerified'] ?? false;
      // if (!isVerified) {
      //   state = state.copyWith(
      //     hasError: true,
      //     errorMessage: 'Only verified users can post',
      //   );
      //   return false;
      // }

      final post = SocialPost(
        id: '',
        authorId: userInfo['uid'],
        authorName: userInfo['displayName'],
        authorPhotoUrl: userInfo['photoUrl'],
        type: PostType.text,
        textContent: content,
        createdAt: DateTime.now(),
      );

      await _socialCollection.add(post.toFirestore());
      state = state.copyWith(isComplete: true, progress: 1.0);
      return true;
    } catch (e) {
      state = state.copyWith(hasError: true, errorMessage: e.toString());
      return false;
    }
  }
}

// ============================================
// SOCIAL ACTIONS
// ============================================

class SocialActions {
  static final _firestore = FirebaseFirestore.instance;

  /// Like a post
  static Future<void> likePost(String postId, String userId) async {
    final docRef = _socialCollection.doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final dislikedBy = List<String>.from(data['dislikedBy'] ?? []);

      if (likedBy.contains(userId)) {
        // Already liked - remove like
        likedBy.remove(userId);
        transaction.update(docRef, {
          'likedBy': likedBy,
          'likes': FieldValue.increment(-1),
        });
      } else {
        // Add like, remove dislike if present
        likedBy.add(userId);
        final wasDisliked = dislikedBy.remove(userId);

        transaction.update(docRef, {
          'likedBy': likedBy,
          'likes': FieldValue.increment(1),
          if (wasDisliked) 'dislikedBy': dislikedBy,
          if (wasDisliked) 'dislikes': FieldValue.increment(-1),
        });
      }
    });
  }

  /// Dislike a post
  static Future<void> dislikePost(String postId, String userId) async {
    final docRef = _socialCollection.doc(postId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final dislikedBy = List<String>.from(data['dislikedBy'] ?? []);

      if (dislikedBy.contains(userId)) {
        // Already disliked - remove dislike
        dislikedBy.remove(userId);
        transaction.update(docRef, {
          'dislikedBy': dislikedBy,
          'dislikes': FieldValue.increment(-1),
        });
      } else {
        // Add dislike, remove like if present
        dislikedBy.add(userId);
        final wasLiked = likedBy.remove(userId);

        transaction.update(docRef, {
          'dislikedBy': dislikedBy,
          'dislikes': FieldValue.increment(1),
          if (wasLiked) 'likedBy': likedBy,
          if (wasLiked) 'likes': FieldValue.increment(-1),
        });
      }
    });
  }

  /// Add a comment
  static Future<void> addComment({
    required String postId,
    required String content,
    required String authorId,
    required String authorName,
    String? authorPhotoUrl,
    String? parentCommentId,
  }) async {
    final comment = PostComment(
      id: '',
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorPhotoUrl: authorPhotoUrl,
      content: content,
      createdAt: DateTime.now(),
      parentCommentId: parentCommentId,
    );

    await _commentsCollection.add(comment.toFirestore());

    // Increment comment count on post
    await _socialCollection.doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  /// Download media file to gallery
  /// R2 has zero egress fees, so this is cost-effective!
  static Future<bool> downloadMedia(
    String url,
    String fileName, {
    bool isVideo = false,
  }) async {
    try {
      // Download file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return false;

      final bytes = response.bodyBytes;

      if (kIsWeb) {
        // Web doesn't support direct gallery save
        // Could implement download via anchor element
        debugPrint('Web download not implemented');
        return false;
      }

      // Get temp directory
      final tempDir = await getTemporaryDirectory();
      final extension = isVideo ? 'mp4' : 'jpg';
      final file = File('${tempDir.path}/$fileName.$extension');

      // Write to temp file
      await file.writeAsBytes(bytes);

      // Save to gallery using Gal
      await Gal.putImage(file.path);

      // Clean up temp file
      await file.delete();

      // Increment download count
      // This is optional analytics tracking
      // await _trackDownload(postId);

      return true;
    } catch (e) {
      debugPrint('Download error: $e');
      return false;
    }
  }

  /// Delete a post (author or admin only)
  static Future<bool> deletePost(
    String postId,
    String userId, {
    bool isAdmin = false,
  }) async {
    try {
      final doc = await _socialCollection.doc(postId).get();
      if (!doc.exists) return false;

      final post = SocialPost.fromFirestore(doc);

      // Allow if user is author OR is admin
      if (post.authorId != userId && !isAdmin) return false;

      // Soft delete - mark as inactive
      await _socialCollection.doc(postId).update({
        'isActive': false,
        'deletedBy': userId,
        'deletedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      debugPrint('Delete post error: $e');
      return false;
    }
  }

  /// Report a post
  static Future<void> reportPost(
    String postId,
    String reporterId,
    String reason,
  ) async {
    await _firestore.collection('post_reports').add({
      'postId': postId,
      'reporterId': reporterId,
      'reason': reason,
      'createdAt': Timestamp.now(),
      'status': 'pending',
    });
  }
}

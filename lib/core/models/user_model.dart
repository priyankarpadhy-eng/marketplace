import 'package:cloud_firestore/cloud_firestore.dart';

/// User roles in the marketplace
enum UserRole { user, shop, admin, designer }

/// Shop application status
enum ShopStatus { none, pending, approved }

/// User model representing a marketplace user
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? nickname; // User-chosen nickname for use across services
  final String? photoUrl;
  final UserRole role;
  final ShopStatus shopStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Shop details (if approved)
  final String? shopName;
  final String? shopCategory;
  final String? shopDescription;
  final List<Map<String, dynamic>> contactNumbers;

  // Social Feed - verified users can post
  final bool isVerified;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.nickname,
    this.photoUrl,
    this.role = UserRole.user,
    this.shopStatus = ShopStatus.none,
    required this.createdAt,
    required this.updatedAt,
    this.shopName,
    this.shopCategory,
    this.shopDescription,
    this.contactNumbers = const [],
    this.isVerified = false,
  });

  /// Get the name to display (nickname if set, otherwise displayName)
  String get publicName =>
      nickname?.isNotEmpty == true ? nickname! : displayName;

  /// Check if user can apply to become a shop
  bool get canApplyForShop =>
      role == UserRole.user && shopStatus == ShopStatus.none;

  /// Check if shop application is pending
  bool get isShopPending => shopStatus == ShopStatus.pending;

  /// Check if user is a shop owner
  bool get isShop => role == UserRole.shop;

  /// Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  /// Check if user can post in social feed
  bool get canPostToSocial => isVerified;

  /// Check if user has a verified phone number
  bool get hasVerifiedPhone {
    // Check if 'isVerified' flag is set (legacy/simple)
    if (isVerified) return true;

    // Check contactNumbers list for any verified number
    return contactNumbers.any((contact) => contact['verified'] == true);
  }

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      nickname: data['nickname'],
      photoUrl: data['photoUrl'],
      role: _parseRole(data['role']),
      shopStatus: _parseShopStatus(data['shopStatus']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shopName: data['shopName'],
      shopCategory: data['shopCategory'],
      shopDescription: data['shopDescription'],
      contactNumbers: List<Map<String, dynamic>>.from(
        data['contactNumbers'] ?? [],
      ),
      isVerified: data['isVerified'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      if (nickname != null) 'nickname': nickname,
      'photoUrl': photoUrl,
      'role': role.name,
      'shopStatus': shopStatus.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (shopName != null) 'shopName': shopName,
      if (shopCategory != null) 'shopCategory': shopCategory,
      if (shopDescription != null) 'shopDescription': shopDescription,
      'contactNumbers': contactNumbers,
      'isVerified': isVerified,
    };
  }

  /// Copy with new values
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? nickname,
    String? photoUrl,
    UserRole? role,
    ShopStatus? shopStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? shopName,
    String? shopCategory,
    String? shopDescription,
    List<Map<String, dynamic>>? contactNumbers,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      shopStatus: shopStatus ?? this.shopStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shopName: shopName ?? this.shopName,
      shopCategory: shopCategory ?? this.shopCategory,
      shopDescription: shopDescription ?? this.shopDescription,
      contactNumbers: contactNumbers ?? this.contactNumbers,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'shop':
        return UserRole.shop;
      case 'admin':
        return UserRole.admin;
      case 'designer':
        return UserRole.designer;
      default:
        return UserRole.user;
    }
  }

  static ShopStatus _parseShopStatus(String? status) {
    switch (status) {
      case 'pending':
        return ShopStatus.pending;
      case 'approved':
        return ShopStatus.approved;
      default:
        return ShopStatus.none;
    }
  }
}

/// Shop request model for applications
class ShopRequest {
  final String uid;
  final String shopName;
  final String category;
  final String description;
  final String? gstId;
  final DateTime timestamp;
  final String status; // 'pending', 'approved', 'rejected'
  final List<Map<String, dynamic>> contactNumbers;

  // User info for admin panel
  final String userEmail;
  final String userName;

  const ShopRequest({
    required this.uid,
    required this.shopName,
    required this.category,
    required this.description,
    this.gstId,
    required this.timestamp,
    this.status = 'pending',
    required this.contactNumbers,
    required this.userEmail,
    required this.userName,
  });

  factory ShopRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ShopRequest(
      uid: doc.id,
      shopName: data['shopName'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      gstId: data['gstId'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      contactNumbers: List<Map<String, dynamic>>.from(
        data['contactNumbers'] ?? [],
      ),
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopName': shopName,
      'category': category,
      'description': description,
      'gstId': gstId,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'contactNumbers': contactNumbers,
      'userEmail': userEmail,
      'userName': userName,
    };
  }
}

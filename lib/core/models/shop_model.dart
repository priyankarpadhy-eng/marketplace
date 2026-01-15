import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a validated Shop in the marketplace
class ShopModel {
  final String id; // Usually matches the User UID
  final String ownerId;
  final String ownerEmail;
  final String ownerName;
  final String shopName;
  final String category; // 'restaurant', 'fashion', etc.
  final String description;
  final List<Map<String, dynamic>> contactNumbers;
  final double rating;
  final int ratingCount;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShopModel({
    required this.id,
    required this.ownerId,
    required this.ownerEmail,
    required this.ownerName,
    required this.shopName,
    required this.category,
    required this.description,
    required this.contactNumbers,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerEmail: data['ownerEmail'] ?? '',
      ownerName: data['ownerName'] ?? '',
      shopName: data['shopName'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      contactNumbers: List<Map<String, dynamic>>.from(
        data['contactNumbers'] ?? [],
      ),
      rating: (data['rating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'ownerName': ownerName,
      'shopName': shopName,
      'category': category,
      'description': description,
      'contactNumbers': contactNumbers,
      'rating': rating,
      'ratingCount': ratingCount,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

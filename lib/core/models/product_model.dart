import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a product in a Shop
class ProductModel {
  final String id;
  final String shopId;
  final String name;
  final String description;
  final double price;
  final List<String> images;
  final String category; // e.g. 'Men', 'Appetizer'
  final bool isAvailable;

  // Dynamic options like Size, Color, Add-ons
  // Example: [{'name': 'Size', 'values': ['S', 'M', 'L'], 'isRequired': true}]
  final List<Map<String, dynamic>> options;

  // Specific data based on shop type
  // Restaurant: {'ingredients': ['Cheese', 'Tomato'], 'isVeg': true}
  // Fashion: {'material': 'Cotton', 'gender': 'Unisex'}
  final Map<String, dynamic> typeSpecificData;

  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    this.isAvailable = true,
    this.options = const [],
    this.typeSpecificData = const {},
    required this.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      images: List<String>.from(data['images'] ?? []),
      category: data['category'] ?? 'General',
      isAvailable: data['isAvailable'] ?? true,
      options: List<Map<String, dynamic>>.from(data['options'] ?? []),
      typeSpecificData: Map<String, dynamic>.from(
        data['typeSpecificData'] ?? {},
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopId': shopId,
      'name': name,
      'description': description,
      'price': price,
      'images': images,
      'category': category,
      'isAvailable': isAvailable,
      'options': options,
      'typeSpecificData': typeSpecificData,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

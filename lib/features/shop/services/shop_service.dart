import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/shop_model.dart';
import '../../../core/models/product_model.dart';

final shopServiceProvider = Provider((ref) => ShopService());

class ShopService {
  final _firestore = FirebaseFirestore.instance;

  // Get shops by category
  Stream<List<ShopModel>> getShopsByCategory(String category) {
    return _firestore
        .collection('shops')
        .where('category', isEqualTo: category)
        .where('isVerified', isEqualTo: true) // Only verified shops? Probably.
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ShopModel.fromFirestore(doc)).toList(),
        );
  }

  // Get products by shop ID
  Stream<List<ProductModel>> getProductsByShopId(String shopId) {
    return _firestore
        .collection('products')
        .where('shopId', isEqualTo: shopId)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList(),
        );
  }
}

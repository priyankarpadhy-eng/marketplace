import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/shop_model.dart';
import '../../core/models/product_model.dart';
import '../../core/theme/uber_money_theme.dart';
import '../shop/services/shop_service.dart';

final foodShopsProvider = StreamProvider<List<ShopModel>>((ref) {
  return ref.watch(shopServiceProvider).getShopsByCategory('Food & Groceries');
});

// We need a way to fetch products for a LIST of shops efficiently or individually.
// For MVP, we'll having a component that fetches products for a single shop.

class FoodGroceriesScreen extends ConsumerWidget {
  const FoodGroceriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(foodShopsProvider);

    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Food & Groceries'),
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: shopsAsync.when(
        data: (shops) {
          if (shops.isEmpty) {
            return const Center(child: Text('No Food & Grocery shops found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              return _ShopProductsSection(shop: shops[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ShopProductsSection extends ConsumerWidget {
  final ShopModel shop;

  const _ShopProductsSection({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We create a unique provider or just generic stream for this shop
    final productsAsync = ref.watch(shopProductsProvider(shop.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.store, color: Colors.orange),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.shopName,
                    style: UberMoneyTheme.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    shop.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UberMoneyTheme.caption,
                  ),
                ],
              ),
            ),
            if (shop.rating > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      shop.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Products List
        productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'No products available',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
            // Vertical list of products for this shop? Or Horizontal?
            // "Show it in the food and groceries page with every item details with the shop name"
            // Let's do a vertical list of products here, making the page essentially a list of lists.
            // But a list of lists scrollable? No, just Column.
            return Column(
              children: products
                  .map(
                    (product) =>
                        _ProductItem(product: product, shopName: shop.shopName),
                  )
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: LinearProgressIndicator(color: Colors.orange),
          ),
          error: (e, s) => Text('Error loading products: $e'),
        ),
      ],
    );
  }
}

// Helper provider using family
final shopProductsProvider = StreamProvider.family<List<ProductModel>, String>((
  ref,
  shopId,
) {
  return ref.watch(shopServiceProvider).getProductsByShopId(shopId);
});

class _ProductItem extends StatelessWidget {
  final ProductModel product;
  final String shopName;

  const _ProductItem({required this.product, required this.shopName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[200],
              child: product.images.isNotEmpty
                  ? Image.network(product.images.first, fit: BoxFit.cover)
                  : const Icon(Icons.fastfood, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        shopName, // "with the shop name"
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

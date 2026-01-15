import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace/core/models/product_model.dart';
import 'package:marketplace/core/theme/uber_money_theme.dart';
import 'package:marketplace/features/auth/auth_controller.dart';
import 'package:marketplace/core/layout/responsive_center.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Common Fields
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final List<String> _images = []; // Placeholder for image URLs
  bool _isAvailable = true;

  // Type Specific Controllers
  // Food
  bool _isVeg = true;
  final _ingredientsController = TextEditingController();
  String _spiciness = 'Medium';

  // Fashion
  final List<String> _selectedSizes = [];
  final _materialController = TextEditingController();

  // Electronics
  final _warrantyController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _ingredientsController.dispose();
    _materialController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  Future<void> _submitProduct(String shopId, String category) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Build Type Specific Map
      final Map<String, dynamic> typeData = {};
      final List<Map<String, dynamic>> options = [];

      if (category.contains('Food')) {
        typeData['isVeg'] = _isVeg;
        typeData['ingredients'] = _ingredientsController.text
            .split(',')
            .map((e) => e.trim())
            .toList();
        typeData['spiciness'] = _spiciness;
      } else if (category.contains('Fashion') ||
          category.contains('Clothing')) {
        typeData['material'] = _materialController.text.trim();
        if (_selectedSizes.isNotEmpty) {
          options.add({
            'name': 'Size',
            'values': _selectedSizes,
            'isRequired': true,
          });
        }
      } else if (category.contains('Electronics')) {
        typeData['warranty'] = _warrantyController.text.trim();
      }

      final product = ProductModel(
        id: '', // Firestore will generate ID if we use .add(), but better to generate first
        shopId: shopId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        images: _images, // TODO: Implement Image Upload
        category: category,
        isAvailable: _isAvailable,
        options: options,
        typeSpecificData: typeData,
        createdAt: DateTime.now(),
      );

      // Write to shops/{shopId}/products
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(shopId)
          .collection('products')
          .add(product.toFirestore()); // Let Firestore generate ID

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product Added Successfully!')),
        );
        context.pop(); // Return to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    if (authState is! AuthAuthenticated || !authState.user.isShop) {
      return const Scaffold(body: Center(child: Text('Unauthorized')));
    }

    final user = authState.user;
    final shopCategory = user.shopCategory ?? 'General';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: ResponsiveCenterWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(shopCategory),
                const SizedBox(height: 24),

                // Common Fields
                _buildTextField('Product Name', _nameController),
                const SizedBox(height: 16),
                _buildTextField('Price', _priceController, isNumber: true),
                const SizedBox(height: 16),
                _buildTextField('Description', _descController, maxLines: 3),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Available in Stock'),
                  value: _isAvailable,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
                const Divider(height: 32),

                // Dynamic Section
                Text(
                  'Category Details ($shopCategory)',
                  style: UberMoneyTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildDynamicFields(shopCategory),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _submitProduct(user.uid, shopCategory),
                    style: UberMoneyTheme.primaryButtonStyle,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('List Item'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UberMoneyTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: UberMoneyTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(
            _getCategoryIcon(category),
            size: 32,
            color: UberMoneyTheme.primary,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New Listing', style: UberMoneyTheme.labelLarge),
              Text(category, style: UberMoneyTheme.headlineMedium),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('Food')) return Icons.restaurant_menu;
    if (category.contains('Fashion')) return Icons.checkroom;
    if (category.contains('Electronics')) return Icons.devices;
    return Icons.store;
  }

  Widget _buildDynamicFields(String category) {
    if (category.contains('Food')) {
      return Column(
        children: [
          SwitchListTile(
            title: const Text('Vegetarian?'),
            value: _isVeg,
            onChanged: (val) => setState(() => _isVeg = val),
          ),
          _buildTextField(
            'Ingredients (comma separated)',
            _ingredientsController,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _spiciness,
            decoration: const InputDecoration(labelText: 'Spiciness Level'),
            items: [
              'Mild',
              'Medium',
              'Hot',
              'Extra Hot',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _spiciness = val!),
          ),
        ],
      );
    }

    if (category.contains('Fashion') || category.contains('Clothing')) {
      return Column(
        children: [
          _buildTextField('Material', _materialController),
          const SizedBox(height: 16),
          const Text(
            'Available Sizes',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Wrap(
            spacing: 8,
            children: ['XS', 'S', 'M', 'L', 'XL', 'XXL'].map((size) {
              final isSelected = _selectedSizes.contains(size);
              return FilterChip(
                label: Text(size),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selected
                        ? _selectedSizes.add(size)
                        : _selectedSizes.remove(size);
                  });
                },
              );
            }).toList(),
          ),
        ],
      );
    }

    if (category.contains('Electronics')) {
      return _buildTextField('Warranty Period', _warrantyController);
    }

    return const Text('No specific options for this category.');
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
    );
  }
}

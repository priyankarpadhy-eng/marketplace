import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/uber_money_theme.dart';
import '../auth/auth_controller.dart';

/// Shop Application Screen
/// Form for users to apply to become a shop
class ShopApplicationScreen extends ConsumerStatefulWidget {
  const ShopApplicationScreen({super.key});

  @override
  ConsumerState<ShopApplicationScreen> createState() =>
      _ShopApplicationScreenState();
}

class _ShopApplicationScreenState extends ConsumerState<ShopApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _gstController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Electronics',
    'Fashion & Clothing',
    'Food & Groceries',
    'Home & Living',
    'Health & Beauty',
    'Sports & Outdoors',
    'Books & Stationery',
    'Automotive',
    'Other',
  ];

  final List<Map<String, dynamic>> _contactNumbers = [
    {
      'number': '',
      'type': 'primary',
      'verified': false,
      'controller': TextEditingController(),
    },
  ];

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _gstController.dispose();
    for (var contact in _contactNumbers) {
      if (contact['controller'] is TextEditingController) {
        (contact['controller'] as TextEditingController).dispose();
      }
    }
    super.dispose();
  }

  void _addContactNumber() {
    if (_contactNumbers.length >= 3) return;
    setState(() {
      _contactNumbers.add({
        'number': '',
        'type': 'secondary',
        'verified': false,
        'controller': TextEditingController(),
      });
    });
  }

  void _removeContactNumber(int index) {
    setState(() {
      final controller =
          _contactNumbers[index]['controller'] as TextEditingController;
      controller.dispose();
      _contactNumbers.removeAt(index);
    });
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }

    // Check primary
    if (_contactNumbers.where((c) => c['type'] == 'primary').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primary contact number is required')),
      );
      return;
    }

    // Ensure all numbers are captured from controllers
    for (var contact in _contactNumbers) {
      contact['number'] = (contact['controller'] as TextEditingController).text
          .trim();
      contact['verified'] = true; // Manual verify by admin later
    }

    setState(() => _isLoading = true);

    // Prepare contacts for storage (remove controller)
    final contactsToSave = _contactNumbers
        .map(
          (c) => {
            'number': c['number'],
            'type': c['type'],
            'verified': c['verified'],
          },
        )
        .toList();

    final success = await ref
        .read(authControllerProvider.notifier)
        .submitShopApplication(
          shopName: _shopNameController.text.trim(),
          category: _selectedCategory!,
          description: _descriptionController.text.trim(),
          gstId: _gstController.text.trim().isNotEmpty
              ? _gstController.text.trim()
              : null,
          contactNumbers: contactsToSave,
        );

    setState(() => _isLoading = false);

    if (success && mounted) {
      _showSuccessDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit application. Please try again.'),
          backgroundColor: UberMoneyTheme.error,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: UberMoneyTheme.borderRadiusLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: UberMoneyTheme.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: UberMoneyTheme.accent,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Application Submitted!',
              style: UberMoneyTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll review your application and notify you once it\'s approved.',
              style: UberMoneyTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/home');
                },
                style: UberMoneyTheme.primaryButtonStyle,
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Open Your Shop', style: UberMoneyTheme.titleLarge),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: UberMoneyTheme.spacingLG),

              // Form Fields
              _buildFormSection(),
              const SizedBox(height: UberMoneyTheme.spacingXL),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: UberMoneyTheme.spacingMD),

              // Terms
              _buildTermsText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF000000), Color(0xFF1A1A2E)],
        ),
        borderRadius: UberMoneyTheme.borderRadiusMedium,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: UberMoneyTheme.accent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront,
              color: UberMoneyTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Become a Seller',
                  style: UberMoneyTheme.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in your shop details to get started',
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
      decoration: UberMoneyTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shop Name
          _buildLabel('Shop Name', isRequired: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _shopNameController,
            decoration: UberMoneyTheme.inputDecoration(
              hintText: 'Enter your shop name',
              prefixIcon: const Icon(
                Icons.store,
                color: UberMoneyTheme.textSecondary,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter shop name';
              }
              if (value.trim().length < 3) {
                return 'Shop name must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Category
          _buildLabel('Category', isRequired: true),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            decoration: UberMoneyTheme.inputDecoration(
              hintText: 'Select a category',
              prefixIcon: const Icon(
                Icons.category,
                color: UberMoneyTheme.textSecondary,
              ),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategory = value);
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a category';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Description
          _buildLabel('Description', isRequired: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: UberMoneyTheme.inputDecoration(
              hintText: 'Describe your shop and what you sell...',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a description';
              }
              if (value.trim().length < 20) {
                return 'Description must be at least 20 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Contact Numbers (New Section)
          _buildContactSection(),
          const SizedBox(height: 20),

          // GST/ID (Optional)
          _buildLabel('GST/Business ID', isRequired: false),
          const SizedBox(height: 8),
          TextFormField(
            controller: _gstController,
            decoration: UberMoneyTheme.inputDecoration(
              hintText: 'Enter GST or business ID (optional)',
              prefixIcon: const Icon(
                Icons.badge,
                color: UberMoneyTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caution Card
        const SizedBox(height: 16),

        _buildLabel('Shop Contact Number(s)', isRequired: true),
        const SizedBox(height: 8),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _contactNumbers.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final contact = _contactNumbers[index];
            final isPrimary = contact['type'] == 'primary';

            return Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: contact['controller'] as TextEditingController,
                    keyboardType: TextInputType.phone,
                    decoration: UberMoneyTheme.inputDecoration(
                      hintText: 'Enter Phone Number',
                      prefixIcon: Icon(
                        isPrimary ? Icons.phone : Icons.phone_android,
                        color: UberMoneyTheme.textSecondary,
                      ),
                    ),
                    onChanged: (val) {
                      // Auto-update number in map
                      contact['number'] = val.trim();
                      contact['verified'] =
                          true; // Assume verified for submission, actual verif is manual
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (!isPrimary)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeContactNumber(index),
                  ),
              ],
            );
          },
        ),

        if (_contactNumbers.length < 3) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addContactNumber,
            icon: const Icon(Icons.add),
            label: const Text('Add Another Contact Number'),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text, {required bool isRequired}) {
    return Row(
      children: [
        Text(text, style: UberMoneyTheme.labelLarge),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: UberMoneyTheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitApplication,
        style: UberMoneyTheme.primaryButtonStyle,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Submit Application'),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By submitting this application, you agree to our Seller Terms and Conditions and acknowledge that your information will be reviewed by our team.',
      style: UberMoneyTheme.caption,
      textAlign: TextAlign.center,
    );
  }
}

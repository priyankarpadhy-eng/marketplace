import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace/core/models/campaign_model.dart';
import 'package:marketplace/core/models/user_model.dart';
import 'package:marketplace/core/theme/uber_money_theme.dart';
import 'package:marketplace/features/shop/services/campaign_service.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  final UserModel user;
  final bool
  isSelfMade; // True for "Make Yourself", False for "Request Marketplace"

  const CreateCampaignScreen({
    super.key,
    required this.user,
    required this.isSelfMade,
  });

  @override
  ConsumerState<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  int _selectedDurationIndex = 0;
  File? _selectedImage;
  bool _isLoading = false;
  final _transactionIdController = TextEditingController();

  final List<Map<String, dynamic>> _durations = [
    {'days': 1, 'price': 70, 'label': '1 Day'},
    {'days': 2, 'price': 130, 'label': '2 Days'},
    {'days': 3, 'price': 170, 'label': '3 Days'},
    {'days': 7, 'price': 300, 'label': '1 Week'},
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  double get _currentPrice =>
      _durations[_selectedDurationIndex]['price'].toDouble();
  int get _currentDays => _durations[_selectedDurationIndex]['days'];

  Future<void> _submitCampaign() async {
    if (widget.isSelfMade && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a banner image')),
      );
      return;
    }
    if (_transactionIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter transaction ID/UTR')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(campaignServiceProvider)
          .createCampaign(
            shopId: widget.user.uid,
            shopName: widget.user.shopName ?? 'Unknown Shop',
            bannerImage: _selectedImage,
            type: widget.isSelfMade
                ? CampaignType.self
                : CampaignType.marketplace,
            durationDays: _currentDays,
            amountPaid: _currentPrice,
            transactionId: _transactionIdController.text.trim(),
          );

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Campaign Submitted'),
          content: const Text(
            'Thanks for using our service. Your campaign will be live after admin verification. Stay tuned, we will update you!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close Dialog
                Navigator.of(context).pop(); // Go back from screen
              },
              child: const Text('Great!'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelfMade ? 'Create Campaign' : 'Request Campaign'),
        backgroundColor: UberMoneyTheme.backgroundPrimary,
      ),
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Section
            if (widget.isSelfMade) ...[
              Text('Banner Image', style: UberMoneyTheme.titleLarge),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text('Tap to upload banner'),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Pricing Section
            Text('Select Duration', style: UberMoneyTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_durations.length, (index) {
                final isSelected = _selectedDurationIndex == index;
                final plan = _durations[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedDurationIndex = index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width:
                        (MediaQuery.of(context).size.width - 44) /
                        2, // 2 items per row
                    decoration: BoxDecoration(
                      color: isSelected ? UberMoneyTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? UberMoneyTheme.primary
                            : Colors.grey[300]!,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['label'],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${plan['price']}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : UberMoneyTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '₹${(plan['price'] / plan['days']).toStringAsFixed(0)}/day',
                          style: TextStyle(
                            color: isSelected ? Colors.white70 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Payment Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment Details', style: UberMoneyTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Amount to Pay: ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '₹${_currentPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: UberMoneyTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'UPI ID:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'marketplace@upi',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(
                            const ClipboardData(text: 'marketplace@upi'),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('UPI ID copied')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _transactionIdController,
                    decoration: InputDecoration(
                      labelText: 'Enter Transaction ID / UTR',
                      hintText: 'e.g. 123456789012',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCampaign,
                style: UberMoneyTheme.primaryButtonStyle.copyWith(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Create Campaign'),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

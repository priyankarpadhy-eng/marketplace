import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace/core/models/campaign_model.dart';
import 'package:marketplace/core/theme/uber_money_theme.dart';
import 'package:marketplace/core/services/r2_storage_service.dart';
import 'package:marketplace/features/auth/auth_controller.dart';
import 'package:marketplace/features/shop/services/campaign_service.dart';

class DesignerPanelScreen extends ConsumerWidget {
  const DesignerPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final campaignsAsync = ref.watch(designRequestedCampaignsProvider);

    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Designer Panel'),
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
              context.go('/login');
            },
          ),
        ],
      ),
      body: campaignsAsync.when(
        data: (campaigns) {
          if (campaigns.isEmpty) {
            return const Center(child: Text('No pending designs.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: campaigns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _idxCampaignCard(context, campaigns[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _idxCampaignCard(BuildContext context, CampaignModel campaign) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: UberMoneyTheme.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                campaign.shopName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Needs Design',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Duration: ${campaign.durationDays} days',
            style: UberMoneyTheme.bodyMedium,
          ),
          Text(
            'Paid: ₹${campaign.amountPaid.toStringAsFixed(0)}',
            style: UberMoneyTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => _UploadDesignDialog(campaign: campaign),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Design'),
              style: ElevatedButton.styleFrom(
                backgroundColor: UberMoneyTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadDesignDialog extends ConsumerStatefulWidget {
  final CampaignModel campaign;
  const _UploadDesignDialog({required this.campaign});

  @override
  ConsumerState<_UploadDesignDialog> createState() =>
      _UploadDesignDialogState();
}

class _UploadDesignDialogState extends ConsumerState<_UploadDesignDialog> {
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Read bytes for both web and mobile compatibility
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _saveDesign() async {
    if (_imageBytes == null || _selectedImage == null) return;

    setState(() => _isLoading = true);
    try {
      // Use bytes-based upload for web compatibility
      final r2Service = R2StorageService();
      final result = await r2Service.uploadFile(
        fileBytes: _imageBytes!,
        fileName: _selectedImage!.name,
        folder: 'campaigns',
        contentType: 'image/jpeg',
      );

      if (result.success && result.url != null) {
        // Update campaign in Firestore
        await FirebaseFirestore.instance
            .collection('campaigns')
            .doc(widget.campaign.id)
            .update({
              'bannerUrl': result.url,
              'status': CampaignStatus.pending.name,
            });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Design submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result.error ?? 'Upload failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload Banner Design'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Design for: ${widget.campaign.shopName}',
              style: UberMoneyTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: 320,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(
                    color: _imageBytes != null
                        ? Colors.green
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to select image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recommended: 1200x600px',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Uploading...', style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _imageBytes == null || _isLoading ? null : _saveDesign,
          style: ElevatedButton.styleFrom(
            backgroundColor: UberMoneyTheme.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save & Submit'),
        ),
      ],
    );
  }
}

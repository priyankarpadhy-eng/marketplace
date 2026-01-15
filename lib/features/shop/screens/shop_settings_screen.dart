import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace/core/theme/uber_money_theme.dart';
import 'package:marketplace/features/auth/auth_controller.dart';
import 'package:marketplace/features/shared/widgets/phone_verification_settings.dart';
import 'create_campaign_screen.dart';

class ShopSettingsScreen extends ConsumerWidget {
  const ShopSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Settings'),
        backgroundColor: UberMoneyTheme.backgroundPrimary,
      ),
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PhoneVerificationSettings(user: user),
              const SizedBox(height: 24),
              _buildCampaignSection(context, ref),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCampaignSection(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.indigo.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.campaign,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Campaign',
                      style: UberMoneyTheme.headlineMedium.copyWith(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Boost your sales instantly',
                      style: UberMoneyTheme.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showCampaignDialog(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('View Details'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCampaignDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Image/Icon
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.rocket_launch,
                      size: 48,
                      color: Colors.indigo.shade600,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GROW WITH CAMPAIGNS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reach Everyone in One Click',
                      style: UberMoneyTheme.headlineMedium.copyWith(
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Campaigns help you reach every user on the app instantly. It is the most effective way to advertise your shop at a very low cost.',
                      style: UberMoneyTheme.bodyMedium.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 24),

                    _buildFeatureItem(
                      Icons.touch_app,
                      'Easy Outreach',
                      'Connect with thousands of customers with just one click.',
                    ),
                    _buildFeatureItem(
                      Icons.image,
                      'Flexible Branding',
                      'Upload your own banner or request our team to design one for you.',
                    ),
                    _buildFeatureItem(
                      Icons.monetization_on,
                      'Cost Effective',
                      'Premium advertising that fits your budget.',
                    ),

                    const SizedBox(height: 24),
                    Text('Perfect When You:', style: UberMoneyTheme.titleLarge),
                    const SizedBox(height: 12),
                    _buildUseCase('🎉', 'Are offering special discounts'),
                    _buildUseCase('📈', 'Want to expand your customer base'),
                    _buildUseCase('🆕', 'Need to acquire new customers'),

                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleCreateCampaign(
                                context,
                                ref,
                                isSelfMade: false,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide(color: Colors.indigo.shade600),
                              foregroundColor: Colors.indigo.shade600,
                            ),
                            child: const Text('Request Marketplace'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleCreateCampaign(
                                context,
                                ref,
                                isSelfMade: true,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Make Yourself'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCreateCampaign(
    BuildContext context,
    WidgetRef ref, {
    required bool isSelfMade,
  }) {
    if (isSelfMade) {
      // Show Caution Dialog for Self-Made
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'Design Guidelines',
                  style: UberMoneyTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/campaign_example.png',
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Creating a campaign without a professionally designed banner like the one above will result in cancellation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'A good design gets significantly higher user engagement!',
                  textAlign: TextAlign.center,
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToCreateScreen(context, ref, true);
                    },
                    style: UberMoneyTheme.primaryButtonStyle,
                    child: const Text('Understood'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Direct navigation for Request Marketplace
      _navigateToCreateScreen(context, ref, false);
    }
  }

  void _navigateToCreateScreen(
    BuildContext context,
    WidgetRef ref,
    bool isSelfMade,
  ) {
    if (context.mounted) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreateCampaignScreen(user: user, isSelfMade: isSelfMade),
          ),
        );
      }
    }
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.indigo.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUseCase(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

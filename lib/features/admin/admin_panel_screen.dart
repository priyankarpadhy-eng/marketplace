import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:marketplace/features/shared/widgets/phone_verification_settings.dart';
import '../../core/theme/uber_money_theme.dart';
import '../../core/models/user_model.dart';
import '../../core/models/campaign_model.dart';
import '../shop/services/campaign_service.dart';
import '../auth/auth_controller.dart';

/// Admin Panel Screen
/// Dashboard for Admins to manage shop requests and own settings
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingRequestsAsync = ref.watch(pendingShopRequestsProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: UberMoneyTheme.backgroundCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/ride'),
        ),
        title: Text('Admin Dashboard', style: UberMoneyTheme.headlineMedium),
        bottom: TabBar(
          controller: _tabController,
          labelColor: UberMoneyTheme.primary,
          unselectedLabelColor: UberMoneyTheme.textSecondary,
          indicatorColor: UberMoneyTheme.primary,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Shop Requests'),
            const Tab(text: 'Ad Campaigns'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Settings'),
                  if (userAsync.value != null &&
                      !_isUserVerified(userAsync.value!))
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: UberMoneyTheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));

          final isVerified = _isUserVerified(user);

          return Column(
            children: [
              if (!isVerified)
                Container(
                  width: double.infinity,
                  color: UberMoneyTheme.warning.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFB8860B),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Identity Verification Required',
                              style: UberMoneyTheme.labelLarge.copyWith(
                                color: const Color(0xFFB8860B),
                              ),
                            ),
                            const Text(
                              'Please verify your phone number in Settings.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF856404),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _tabController.animateTo(2),
                        child: const Text('Verify'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Shop Requests
                    _RequestsTab(pendingRequestsAsync: pendingRequestsAsync),

                    // Tab 2: Ad Campaigns
                    const _CampaignsTab(),

                    // Tab 3: Settings
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [PhoneVerificationSettings(user: user)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  bool _isUserVerified(UserModel user) {
    return user.hasVerifiedPhone;
  }
}

class _CampaignsTab extends ConsumerWidget {
  const _CampaignsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCampaignsAsync = ref.watch(pendingCampaignsProvider);

    return pendingCampaignsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (campaigns) {
        if (campaigns.isEmpty) {
          return const Center(child: Text('No Pending Review Campaigns'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: campaigns.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _CampaignCard(campaign: campaigns[index]);
          },
        );
      },
    );
  }
}

class _CampaignCard extends ConsumerStatefulWidget {
  final CampaignModel campaign;
  const _CampaignCard({required this.campaign});

  @override
  ConsumerState<_CampaignCard> createState() => _CampaignCardState();
}

class _CampaignCardState extends ConsumerState<_CampaignCard> {
  bool _isLoading = false;

  Future<void> _approve() async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(campaignServiceProvider)
          .approveCampaign(widget.campaign.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Campaign Approved')));
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

  Future<void> _reject() async {
    // Show simple rejection reason dialog if needed, for now just reject
    setState(() => _isLoading = true);
    try {
      await ref
          .read(campaignServiceProvider)
          .rejectCampaign(widget.campaign.id, 'Admin Rejected');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Campaign Rejected')));
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
    final c = widget.campaign;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.shopName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    c.type == CampaignType.self
                        ? 'Self-Made'
                        : 'Marketplace Request',
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: c.type == CampaignType.self
                      ? Colors.blue
                      : Colors.purple,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (c.bannerUrl != null)
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(c.bannerUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(child: Text('No Banner Image (Request)')),
              ),
            const SizedBox(height: 12),
            Text('Duration: ${c.durationDays} Days'),
            Text('Paid: ₹${c.amountPaid}'),
            if (c.transactionId != null)
              Text('Transaction ID: ${c.transactionId}'),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _approve,
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final AsyncValue<List<ShopRequest>> pendingRequestsAsync;

  const _RequestsTab({required this.pendingRequestsAsync});

  @override
  Widget build(BuildContext context) {
    return pendingRequestsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: UberMoneyTheme.textMuted,
                ),
                const SizedBox(height: 16),
                const Text('No Pending Requests'),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _RequestCard(request: requests[index]);
          },
        );
      },
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final ShopRequest request;

  const _RequestCard({required this.request});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _isProcessing = false;

  Future<void> _approveRequest() async {
    setState(() => _isProcessing = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .approveShopRequest(widget.request.uid);

    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Shop approved successfully!' : 'Failed to approve shop',
          ),
          backgroundColor: success
              ? UberMoneyTheme.accent
              : UberMoneyTheme.error,
        ),
      );
    }
  }

  Future<void> _rejectRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application?'),
        content: const Text(
          'Are you sure you want to reject this shop application?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: UberMoneyTheme.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .rejectShopRequest(widget.request.uid);

    setState(() => _isProcessing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Application rejected' : 'Failed to reject application',
          ),
          backgroundColor: success
              ? UberMoneyTheme.textSecondary
              : UberMoneyTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;

    return Container(
      padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
      decoration: UberMoneyTheme.cardDecorationElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: UberMoneyTheme.accentBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storefront,
                  color: UberMoneyTheme.accentBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.shopName, style: UberMoneyTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(request.category, style: UberMoneyTheme.bodyMedium),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  'Pending',
                  style: UberMoneyTheme.labelMedium.copyWith(
                    color: const Color(0xFFB8860B),
                  ),
                ),
                backgroundColor: UberMoneyTheme.warning.withOpacity(0.2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(request.userName, style: UberMoneyTheme.labelLarge),
          Text(request.userEmail, style: UberMoneyTheme.caption),
          const SizedBox(height: 12),
          // Contact Numbers
          if (request.contactNumbers.isNotEmpty)
            ...request.contactNumbers.map((c) {
              final number = c['number']?.toString() ?? '';
              final type = c['type']?.toString() ?? 'secondary';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      type == 'primary' ? Icons.phone : Icons.phone_android,
                      size: 16,
                      color: UberMoneyTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$number (${type.toUpperCase()})',
                      style: UberMoneyTheme.bodyMedium,
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('tel:$number');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.call, size: 16),
                        label: const Text('Call'),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          Text(
            request.description,
            style: UberMoneyTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (request.gstId != null && request.gstId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'GST: ${request.gstId}',
                style: UberMoneyTheme.labelMedium,
              ),
            ),
          const SizedBox(height: 16),
          if (_isProcessing)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _rejectRequest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UberMoneyTheme.error,
                      side: const BorderSide(color: UberMoneyTheme.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _approveRequest,
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

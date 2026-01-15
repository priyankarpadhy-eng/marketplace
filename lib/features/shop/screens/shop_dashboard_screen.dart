import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace/core/models/order_model.dart';
import 'package:marketplace/core/layout/responsive_layout.dart';
import 'package:marketplace/core/theme/uber_money_theme.dart';
import 'package:marketplace/features/shop/services/reconciliation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class ShopDashboardScreen extends ConsumerStatefulWidget {
  const ShopDashboardScreen({super.key});

  @override
  ConsumerState<ShopDashboardScreen> createState() =>
      _ShopDashboardScreenState();
}

class _ShopDashboardScreenState extends ConsumerState<ShopDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReconciliationService _reconciliationService = ReconciliationService();
  bool _isProcessing = false;
  int _selectedIndex = 0; // For Desktop Rail

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleAutoVerify() async {
    // Platform check to avoid crashing on unsupported platforms
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bulk Verification is only supported on Mobile (Android/iOS) for now due to ML Kit limitations.',
          ),
        ),
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isProcessing = true);

    try {
      final File imageFile = File(image.path);
      final result = await _reconciliationService.processStatement(imageFile);

      if (mounted) {
        _showResultDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing statement: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showResultDialog(ReconciliationResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Auto-Verify Result', style: UberMoneyTheme.headlineMedium),
        shape: RoundedRectangleBorder(
          borderRadius: UberMoneyTheme.borderRadiusLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Found ${result.totalScannedUTRs} UTRs in statement.',
              style: UberMoneyTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _buildResultRow(
              'Matched Orders',
              '${result.matchedOrdersCount}',
              UberMoneyTheme.success,
            ),
            _buildResultRow(
              'Pending (Not Found)',
              '${result.unmatchedOrdersCount}',
              UberMoneyTheme.warning,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (result.matchedOrdersCount > 0)
            ElevatedButton(
              style: UberMoneyTheme.primaryButtonStyle.copyWith(
                backgroundColor: WidgetStateProperty.all(UberMoneyTheme.accent),
                foregroundColor: WidgetStateProperty.all(
                  UberMoneyTheme.primary,
                ),
              ),
              onPressed: () async {
                final ids = result.matchedOrders
                    .map((o) => o['orderId'] as String)
                    .toList();
                await _reconciliationService.confirmOrders(ids);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Confirmed ${ids.length} orders!')),
                  );
                }
              },
              child: const Text('Confirm Matches'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: UberMoneyTheme.bodyMedium),
          Text(
            value,
            style: UberMoneyTheme.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // ============================================
  // MOBILE LAYOUT
  // ============================================
  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Shop Dashboard'),
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => context.push('/shop-settings'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Settings',
                      style: UberMoneyTheme.labelLarge.copyWith(
                        color: UberMoneyTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.settings,
                      color: UberMoneyTheme.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildStatsSection(),
                _buildVerificationTools(isMobile: true),
                Expanded(
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: UberMoneyTheme.primary,
                        unselectedLabelColor: UberMoneyTheme.textSecondary,
                        indicatorColor: UberMoneyTheme.accent,
                        tabs: const [
                          Tab(text: 'Pending'),
                          Tab(text: 'Confirmed'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            OrderListSection(status: 'verification_pending'),
                            OrderListSection(status: 'confirmed'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/shop/add-product'),
        label: const Text('Add Product'),
        icon: const Icon(Icons.add),
        backgroundColor: UberMoneyTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ============================================
  // DESKTOP LAYOUT
  // ============================================
  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: Colors.white,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              if (index == 2) {
                context.push('/shop-settings');
                return;
              }
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Icon(Icons.store, size: 32, color: UberMoneyTheme.primary),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt),
                selectedIcon: Icon(Icons.list_alt),
                label: Text('Orders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Master Shop Dashboard',
                              style: UberMoneyTheme.headlineLarge,
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/shop/add-product'),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Product'),
                              style: UberMoneyTheme.primaryButtonStyle.copyWith(
                                padding: WidgetStateProperty.all(
                                  const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildStatsSection(),
                        const SizedBox(height: 24),
                        _buildVerificationTools(isMobile: false),
                        const SizedBox(height: 24),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: UberMoneyTheme.shadowSmall,
                            ),
                            child: Column(
                              children: [
                                TabBar(
                                  controller: _tabController,
                                  labelColor: UberMoneyTheme.primary,
                                  unselectedLabelColor:
                                      UberMoneyTheme.textSecondary,
                                  indicatorColor: UberMoneyTheme.accent,
                                  tabs: const [
                                    Tab(text: 'Pending'),
                                    Tab(text: 'Confirmed'),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      OrderListSection(
                                        status: 'verification_pending',
                                      ),
                                      OrderListSection(status: 'confirmed'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Total Sales',
              value: '₹12,450',
              color: UberMoneyTheme.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Pending',
              value: '8',
              color: UberMoneyTheme.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              label: 'Visitors',
              value: '142',
              color: UberMoneyTheme.info,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTools({required bool isMobile}) {
    // Android Only Indicator
    bool showSMS = !kIsWeb && Platform.isAndroid;
    // Web/Desktop Only Button
    bool showUpload = ResponsiveLayout.isDesktop(context);

    if (!showSMS && !showUpload) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        children: [
          if (showSMS)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: UberMoneyTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: UberMoneyTheme.accent.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_tethering,
                    color: UberMoneyTheme.accent,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Auto-Verifying via SMS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          if (showUpload)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleAutoVerify,
                style: UberMoneyTheme.primaryButtonStyle.copyWith(
                  backgroundColor: WidgetStateProperty.all(Colors.black),
                ),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Bank Statement (Bulk Verify)'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: UberMoneyTheme.shadowSmall,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: UberMoneyTheme.caption),
          const SizedBox(height: 4),
          Text(
            value,
            style: UberMoneyTheme.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class OrderListSection extends StatelessWidget {
  final String status;

  const OrderListSection({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text('No $status orders', style: UberMoneyTheme.bodyLarge),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = OrderModel.fromFirestore(docs[index]);
            return _OrderCard(order: order);
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final bool isConfirmed = order.status == 'confirmed';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: UberMoneyTheme.shadowSmall,
        border: order.isAiVerified && !isConfirmed
            ? Border.all(color: UberMoneyTheme.accent, width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[100],
                  child: Text(order.userName[0].toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.userName, style: UberMoneyTheme.titleMedium),
                      const SizedBox(height: 4),
                      // Items list (mocked for now in model)
                      Text(
                        '${order.items.length} items',
                        style: UberMoneyTheme.caption,
                      ),
                      if (order.userProvidedUTR != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            // Copy logic
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.copy,
                                size: 12,
                                color: UberMoneyTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'UTR: ${order.userProvidedUTR}',
                                style: UberMoneyTheme.caption.copyWith(
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${order.amount}',
                      style: UberMoneyTheme.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (order.isAiVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: UberMoneyTheme.accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user,
                              size: 12,
                              color: UberMoneyTheme.accent,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'AI Verified',
                              style: TextStyle(
                                fontSize: 10,
                                color: UberMoneyTheme.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Manual Check',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (!isConfirmed) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Reject logic
                        FirebaseFirestore.instance
                            .collection('orders')
                            .doc(order.id)
                            .update({'status': 'rejected'});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.withOpacity(0.5)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Confirm logic
                        FirebaseFirestore.instance
                            .collection('orders')
                            .doc(order.id)
                            .update({'status': 'confirmed'});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UberMoneyTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav_bar.dart';
import 'responsive_center.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/shop/services/campaign_service.dart';
import '../../features/shop/widgets/campaign_popup.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  bool _hasShownCampaigns = false;

  // Navigation items for both mobile bottom nav and desktop rail
  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.directions_car, label: 'Ride'),
    _NavItem(icon: Icons.storefront, label: 'Market'),
    _NavItem(icon: Icons.play_circle, label: 'Social'),
    _NavItem(icon: Icons.notifications, label: 'Activity'),
    _NavItem(icon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen for active campaigns to show popup
    ref.listen<AsyncValue<List<dynamic>>>(activeCampaignsProvider, (
      previous,
      next,
    ) {
      if (!_hasShownCampaigns && next.hasValue && next.value!.isNotEmpty) {
        _hasShownCampaigns = true;
        // Schedule dialog show
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false, // Prevent dismissing by tap
            builder: (context) => CampaignPopup(
              campaigns: next.value!.cast(), // Ensure type safety
              onClose: () => Navigator.of(context).pop(),
            ),
          );
        });
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    if (isDesktop) {
      return _buildDesktopLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  // Mobile layout - Bottom navigation bar
  Widget _buildMobileLayout() {
    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: ResponsiveCenterWrapper(
        maxContentWidth: 500,
        child: BottomNavBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onItemSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }

  // Tablet layout - Navigation rail on left
  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Compact Navigation Rail
          Container(
            width: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // App Logo
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                // Nav Items
                Expanded(
                  child: Column(
                    children: _navItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSelected =
                          widget.navigationShell.currentIndex == index;

                      return _buildRailItem(
                        icon: item.icon,
                        label: item.label,
                        isSelected: isSelected,
                        onTap: () => widget.navigationShell.goBranch(
                          index,
                          initialLocation:
                              index == widget.navigationShell.currentIndex,
                        ),
                        compact: true,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Content area
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  // Desktop layout - Full navigation sidebar
  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          // Full Navigation Sidebar
          Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // App Logo & Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Buy, Sell, Ride',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 32),
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _navItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSelected =
                          widget.navigationShell.currentIndex == index;

                      return _buildRailItem(
                        icon: item.icon,
                        label: item.label,
                        isSelected: isSelected,
                        onTap: () => widget.navigationShell.goBranch(
                          index,
                          initialLocation:
                              index == widget.navigationShell.currentIndex,
                        ),
                        compact: false,
                      );
                    }).toList(),
                  ),
                ),
                // Footer
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Marketplace v1.0',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content area with max width constraint
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: widget.navigationShell,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool compact,
  }) {
    final primaryColor = const Color(0xFF6366F1);

    if (compact) {
      // Tablet - icon only with tooltip
      return Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey[600],
              size: 24,
            ),
          ),
        ),
      );
    } else {
      // Desktop - full item with label
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey[600],
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? primaryColor : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

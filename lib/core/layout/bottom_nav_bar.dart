import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Floating margin
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Deep dark, almost black
          borderRadius: BorderRadius.circular(50), // Stadium shape
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavBarItem(
              icon: Icons.directions_car_filled,
              outlineIcon: Icons.directions_car_outlined,
              label: 'Ride',
              isSelected: selectedIndex == 0,
              activeColor: const Color(0xFF6190E8), // Blue (Matching Ride Card)
              onTap: () => onItemSelected(0),
            ),
            _NavBarItem(
              icon: Icons.shopping_bag,
              outlineIcon: Icons.shopping_bag_outlined,
              label: 'Market',
              isSelected: selectedIndex == 1,
              activeColor: const Color(0xFF00D632), // Green
              onTap: () => onItemSelected(1),
            ),
            _NavBarItem(
              icon: Icons.public,
              outlineIcon: Icons.public_off_outlined,
              label: 'Social',
              isSelected: selectedIndex == 2,
              activeColor: const Color(0xFFFF5277), // Pink
              onTap: () => onItemSelected(2),
            ),
            _NavBarItem(
              icon: Icons.person,
              outlineIcon: Icons.person_outline,
              label: 'Profile',
              isSelected: selectedIndex == 3,
              activeColor: const Color(0xFF7B61FF), // Purple
              onTap: () => onItemSelected(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData? outlineIcon;
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    this.outlineIcon,
    required this.label,
    required this.isSelected,
    this.activeColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we need dark text (for light active colors) or light text (for dark active colors)
    // Simple heuristic: assuming mostly light/vibrant colors -> Black or Dark Grey text looks crispest on them usually.
    // However, if the color is VERY dark, we might need white.
    // Let's stick to the "User Image" aesthetic which had White Pill + Black Text.
    // Colored Pill + Black Text is also very clean if colors are pastel-ish.
    // But user asked for "highlight colour", let's use the activeColor as background.

    // Check luminance?
    final bool isDark = activeColor.computeLuminance() < 0.5;
    final Color textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : (outlineIcon ?? icon),
              color: isSelected ? textColor : Colors.white54,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

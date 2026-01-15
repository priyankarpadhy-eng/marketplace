import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A utility widget to center content and constrain width on Web/Desktop.
/// This ensures mobile-first designs look good on large screens.
class ResponsiveCenterWrapper extends StatelessWidget {
  final Widget child;
  final double maxContentWidth;

  const ResponsiveCenterWrapper({
    super.key,
    required this.child,
    this.maxContentWidth = 600, // Standard mobile/tablet width
  });

  @override
  Widget build(BuildContext context) {
    // Only apply constraints on Web or Desktop (via MediaQuery width check or kIsWeb)
    if (kIsWeb) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: child,
        ),
      );
    }

    // Fallback for app usage (optional check for tablet width could be added here)
    // For now, only web as requested.
    return child;
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// UberMoney Design System
/// Combines Uber's clean utility with Supermoney's financial aesthetic
class UberMoneyTheme {
  // ============================================
  // COLORS
  // ============================================

  /// Background Colors
  static const Color backgroundPrimary = Color(0xFFF5F5F7); // Off-white
  static const Color backgroundCard = Color(0xFFFFFFFF); // Pure white

  /// Primary Colors
  static const Color primary = Color(0xFF000000); // Deep Black (Uber style)
  static const Color accent = Color(0xFF00D632); // Electric Green
  static const Color accentBlue = Color(0xFF0057FF); // Financial Blue

  /// Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A); // Dark Grey (headings)
  static const Color textSecondary = Color(0xFF757575); // Medium Grey (body)
  static const Color textLight = Color(0xFFFFFFFF); // White text
  static const Color textMuted = Color(0xFFB0B0B0); // Muted text

  /// Status Colors
  static const Color success = Color(0xFF00D632);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFDC3545);
  static const Color info = Color(0xFF0057FF);

  /// Vibrant Palette
  static const Color purple = Color(0xFF7B61FF);
  static const Color orange = Color(0xFFFF7E21);
  static const Color teal = Color(0xFF00C9A7);
  static const Color pink = Color(0xFFFF5277);
  static const Color yellow = Color(0xFFFFC107);
  static const Color blue = Color(0xFF4B9FFF);

  static const List<Color> vibrantColors = [
    purple,
    orange,
    teal,
    pink,
    blue,
    yellow,
    accent,
  ];

  /// Border & Divider Colors
  static const Color border = Color(0xFFE5E5E7);
  static const Color divider = Color(0xFFF0F0F2);

  // ============================================
  // BORDER RADIUS
  // ============================================

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0; // Primary radius
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  static BorderRadius get borderRadiusSmall =>
      BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium =>
      BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge =>
      BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge =>
      BorderRadius.circular(radiusXLarge);

  // ============================================
  // SHADOWS (Supermoney Style - Deep, Soft Elevation)
  // ============================================

  static List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 32,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Elevated card shadow (Supermoney premium style)
  static List<BoxShadow> get shadowCard => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  // ============================================
  // SPACING
  // ============================================

  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // ============================================
  // TYPOGRAPHY
  // ============================================

  static TextStyle get displayLarge => GoogleFonts.inter(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static TextStyle get headlineLarge => GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get headlineMedium => GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.15,
    height: 1.35,
  );

  static TextStyle get titleLarge => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static TextStyle get titleMedium => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.45,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle get labelMedium => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.2,
    height: 1.35,
  );

  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.4,
  );

  // ============================================
  // BUTTON STYLES
  // ============================================

  /// Primary button style (Uber-style wide black button)
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: textLight,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
    elevation: 0,
    textStyle: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  /// Accent button style
  static ButtonStyle get accentButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: accent,
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
    elevation: 0,
    textStyle: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
  );

  /// Outlined button style
  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
    side: const BorderSide(color: border, width: 1.5),
    textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
  );

  // ============================================
  // INPUT DECORATION
  // ============================================

  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      hintStyle: bodyMedium.copyWith(color: textMuted),
      labelStyle: labelMedium,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: backgroundCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: error, width: 1),
      ),
    );
  }

  // ============================================
  // CARD DECORATION
  // ============================================

  static BoxDecoration get cardDecoration => BoxDecoration(
    color: backgroundCard,
    borderRadius: borderRadiusMedium,
    boxShadow: shadowCard,
  );

  static BoxDecoration get cardDecorationElevated => BoxDecoration(
    color: backgroundCard,
    borderRadius: borderRadiusLarge,
    boxShadow: shadowLarge,
  );

  // ============================================
  // THEME DATA
  // ============================================

  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: backgroundPrimary,
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: accent,
      surface: backgroundCard,
      error: error,
      onPrimary: textLight,
      onSecondary: textPrimary,
      onSurface: textPrimary,
      onError: textLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundPrimary,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: headlineMedium,
      iconTheme: const IconThemeData(color: textPrimary),
    ),
    cardTheme: CardThemeData(
      color: backgroundCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: borderRadiusMedium),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedButtonStyle),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: backgroundCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadiusMedium,
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: divider,
      thickness: 1,
      space: 1,
    ),
    textTheme: TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
    ),
    iconTheme: const IconThemeData(color: textPrimary, size: 24),
  );
}

/// Custom card widget with Supermoney-style elevation
class UberMoneyCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool elevated;

  const UberMoneyCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(UberMoneyTheme.spacingMD),
        decoration: elevated
            ? UberMoneyTheme.cardDecorationElevated
            : UberMoneyTheme.cardDecoration,
        child: child,
      ),
    );
  }
}

/// Uber-style primary button
class UberButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const UberButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: UberMoneyTheme.outlinedButtonStyle,
          child: _buildChild(),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: UberMoneyTheme.primaryButtonStyle,
        child: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: UberMoneyTheme.textLight,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(text)],
      );
    }

    return Text(text);
  }
}

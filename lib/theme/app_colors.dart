import 'package:flutter/material.dart';

/// Centralised design token system for Precon Wellness.
/// All colours, radii, and spacing constants live here.
/// Never use inline Color(0xFF...) literals in screens — reference this instead.
abstract class AppColors {
  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------
  static const Color primary = Color(0xFF0E7F6E);
  static const Color primaryLight = Color(0xFF17A589); // for dark mode
  static const Color primaryMuted = Color(0x140E7F6E); // 8% opacity tint

  // ---------------------------------------------------------------------------
  // Light Mode
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightBorderSubtle = Color(0xFFF3F4F6);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextMuted = Color(0xFF9CA3AF);
  static const Color lightInputFill = Color(0xFFF9FAFB);

  // ---------------------------------------------------------------------------
  // Dark Mode
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkSurfaceElevated = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2A2A2A);
  static const Color darkBorderSubtle = Color(0xFF222222);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextMuted = Color(0xFF6B7280);
  static const Color darkInputFill = Color(0xFF161616);

  // ---------------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFDC2626);
  static const Color errorMuted = Color(0x14DC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color warningMuted = Color(0x14D97706);
  static const Color success = Color(0xFF059669);
  static const Color successMuted = Color(0x14059669);
  static const Color info = Color(0xFF2563EB);
  static const Color infoMuted = Color(0x142563EB);

  // ---------------------------------------------------------------------------
  // Spacing scale
  // ---------------------------------------------------------------------------
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // ---------------------------------------------------------------------------
  // Border radii
  // ---------------------------------------------------------------------------
  static const double radiusSmall = 8;
  static const double radiusMedium = 10;
  static const double radiusLarge = 12;
  static const double radiusXL = 16; // modals, bottom sheets only

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static Color bg(bool isDark) => isDark ? darkBackground : lightBackground;
  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;
  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color textPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;
  static Color textSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;
  static Color textMuted(bool isDark) => isDark ? darkTextMuted : lightTextMuted;
  static Color inputFill(bool isDark) => isDark ? darkInputFill : lightInputFill;
  static Color brand(bool isDark) => isDark ? primaryLight : primary;
  static Color brandMuted(bool isDark) =>
      isDark ? const Color(0x1F17A589) : primaryMuted;
}

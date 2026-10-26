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

  // Coral marks what needs attention (next session, join call). Use sparingly.
  static const Color accent = Color(0xFFC4533D);
  static const Color accentLight = Color(0xFFE07A63); // for dark mode
  static const Color accentTint = Color(0xFFFCEDE9);
  static const Color accentInkLight = Color(0xFFA8432F); // coral text on the tint

  // ---------------------------------------------------------------------------
  // Light Mode
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFFAF8F5); // warm off-white
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE8E3DC);
  static const Color lightBorderSubtle = Color(0xFFF2EEE8);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextMuted = Color(0xFF9CA3AF);
  static const Color lightInputFill = Color(0xFFFAF8F5);

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
  // Desktop navigation rail (web split view)
  // ---------------------------------------------------------------------------
  static const Color railLight = Color(0xFF12343B);
  static const Color railDark = Color(0xFF0E1F23);
  static const Color railInk = Color(0xFFCFE3E5);
  static const Color railActive = Color(0x1FFFFFFF);

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

  // Health tags: "Take care" level (amber). "Must avoid" reuses coral.
  static const Color cautionInkLight = Color(0xFFB45309);
  static const Color cautionInkDark = Color(0xFFF0A54A);
  static const Color cautionTintLight = Color(0xFFFEF3E2);
  static const Color cautionTintDark = Color(0x21F0A54A);

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
  static Color rail(bool isDark) => isDark ? railDark : railLight;
  static Color accentColor(bool isDark) => isDark ? accentLight : accent;
  static Color accentMuted(bool isDark) => isDark ? const Color(0x24E07A63) : accentTint;
  static Color accentInk(bool isDark) => isDark ? accentLight : accentInkLight;
  static Color cautionInk(bool isDark) => isDark ? cautionInkDark : cautionInkLight;
  static Color cautionMuted(bool isDark) => isDark ? cautionTintDark : cautionTintLight;
  static Color neutralMuted(bool isDark) => isDark ? const Color(0xFF1E1E1E) : lightBorderSubtle;
  static Color brandMuted(bool isDark) =>
      isDark ? const Color(0x1F17A589) : primaryMuted;
}

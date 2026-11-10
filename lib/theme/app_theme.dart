import 'package:flutter/material.dart';
import '../widgets/motion.dart';
import 'app_colors.dart';

/// The single, light theme of the app.
class AppTheme {
  // Bundled (assets/fonts) so the app looks the same on every computer.
  static const _fontFamily = 'PlusJakartaSans';

  static const _pageTransitions = PageTransitionsTheme(builders: {
    TargetPlatform.android: FastPageTransitionsBuilder(),
    TargetPlatform.iOS: FastPageTransitionsBuilder(),
    TargetPlatform.macOS: FastPageTransitionsBuilder(),
    TargetPlatform.windows: FastPageTransitionsBuilder(),
    TargetPlatform.linux: FastPageTransitionsBuilder(),
    TargetPlatform.fuchsia: FastPageTransitionsBuilder(),
  });

  static OutlineInputBorder _outline(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.leaf,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.navy,
      onSecondary: Colors.white,
      tertiary: AppColors.accent,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerLowest: AppColors.lightBackground,
      error: AppColors.error,
    );

    const buttonText = TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0);
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusMedium));

    return ThemeData(
      useMaterial3: true,
      pageTransitionsTheme: _pageTransitions,
      fontFamily: _fontFamily,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: AppColors.lightTextPrimary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          side: const BorderSide(color: AppColors.lightBorderSubtle),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _outline(AppColors.lightBorder),
        enabledBorder: _outline(AppColors.lightBorder),
        focusedBorder: _outline(AppColors.leaf, 2),
        errorBorder: _outline(AppColors.error),
        focusedErrorBorder: _outline(AppColors.error, 2),
        labelStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.lightTextSecondary, fontSize: 13),
        hintStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.lightTextMuted, fontSize: 14),
        errorStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.error, fontSize: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          backgroundColor: AppColors.lightSurface,
          side: const BorderSide(color: AppColors.lightBorder),
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: buttonText.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: buttonShape,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        elevation: 8,
        shadowColor: AppColors.navy.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusXL)),
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.lightTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.lightTextSecondary, fontSize: 14, height: 1.5),
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.lightTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(fontFamily: _fontFamily, color: AppColors.lightTextSecondary, fontSize: 13),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.lightBorder, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(fontFamily: _fontFamily, color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        highlightElevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusLarge)),
        extendedTextStyle: buttonText,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightRaised,
        selectedColor: AppColors.leafTint,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.lightTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        side: const BorderSide(color: AppColors.lightBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.leaf),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontFamily: _fontFamily, color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppColors.radiusXL))),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
        textStyle: const TextStyle(fontFamily: _fontFamily, color: AppColors.lightTextPrimary, fontSize: 14),
      ),
    );
  }
}

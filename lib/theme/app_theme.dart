import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // SHARED
  // ---------------------------------------------------------------------------
  // Bundled (assets/fonts) so the app looks the same on every computer.
  static const _fontFamily = 'Inter';

  static InputDecorationTheme _inputTheme(bool isDark) {
    final borderColor = AppColors.border(isDark);
    final fillColor = AppColors.inputFill(isDark);
    const radius = AppColors.radiusLarge;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      labelStyle: TextStyle(fontFamily: _fontFamily, 
        color: AppColors.textSecondary(isDark),
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: TextStyle(fontFamily: _fontFamily, 
        color: AppColors.textMuted(isDark),
        fontSize: 14,
      ),
      errorStyle: const TextStyle(fontFamily: _fontFamily, 
        color: AppColors.error,
        fontSize: 12,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        ),
        textStyle: const TextStyle(fontFamily: _fontFamily, 
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return Colors.white.withValues(alpha: 0.12);
          }
          return null;
        }),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        side: BorderSide(color: AppColors.border(isDark)),
        minimumSize: const Size(0, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        ),
        textStyle: const TextStyle(fontFamily: _fontFamily, 
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(bool isDark) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        textStyle: const TextStyle(fontFamily: _fontFamily, 
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        ),
      ),
    );
  }

  static CardThemeData _cardTheme(bool isDark) {
    return CardThemeData(
      color: AppColors.surface(isDark),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusLarge),
        side: BorderSide(color: AppColors.border(isDark)),
      ),
      margin: EdgeInsets.zero,
    );
  }

  static AppBarTheme _appBarTheme(bool isDark) {
    return AppBarTheme(
      backgroundColor: AppColors.bg(isDark),
      foregroundColor: AppColors.textPrimary(isDark),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: _fontFamily, 
        color: AppColors.textPrimary(isDark),
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(
        color: AppColors.textSecondary(isDark),
        size: 20,
      ),
    );
  }

  static DialogThemeData _dialogTheme(bool isDark) {
    return DialogThemeData(
      backgroundColor: AppColors.surface(isDark),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusXL),
        side: BorderSide(color: AppColors.border(isDark)),
      ),
      titleTextStyle: TextStyle(fontFamily: _fontFamily, 
        color: AppColors.textPrimary(isDark),
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      contentTextStyle: TextStyle(fontFamily: _fontFamily, 
        color: AppColors.textSecondary(isDark),
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LIGHT THEME
  // ---------------------------------------------------------------------------
  static ThemeData get lightTheme {
    const isDark = false;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerLowest: AppColors.lightBackground,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: _appBarTheme(isDark),
      cardTheme: _cardTheme(isDark),
      inputDecorationTheme: _inputTheme(isDark),
      elevatedButtonTheme: _elevatedButtonTheme(isDark),
      outlinedButtonTheme: _outlinedButtonTheme(isDark),
      textButtonTheme: _textButtonTheme(isDark),
      dialogTheme: _dialogTheme(isDark),
      listTileTheme: ListTileThemeData(
        titleTextStyle: TextStyle(fontFamily: _fontFamily, 
          color: AppColors.textPrimary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(fontFamily: _fontFamily, 
          color: AppColors.textSecondary(isDark),
          fontSize: 13,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.lightTextPrimary,
        contentTextStyle: const TextStyle(fontFamily: _fontFamily, color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBorderSubtle,
        labelStyle: TextStyle(fontFamily: _fontFamily, 
          color: AppColors.textSecondary(isDark),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: AppColors.border(isDark)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DARK THEME
  // ---------------------------------------------------------------------------
  static ThemeData get darkTheme {
    const isDark = true;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryLight,
      brightness: Brightness.dark,
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      secondary: AppColors.primaryLight,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerLowest: AppColors.darkBackground,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: _appBarTheme(isDark),
      cardTheme: _cardTheme(isDark),
      inputDecorationTheme: _inputTheme(isDark),
      elevatedButtonTheme: _elevatedButtonTheme(isDark),
      outlinedButtonTheme: _outlinedButtonTheme(isDark),
      textButtonTheme: _textButtonTheme(isDark),
      dialogTheme: _dialogTheme(isDark),
      listTileTheme: ListTileThemeData(
        titleTextStyle: TextStyle(fontFamily: _fontFamily, 
          color: AppColors.textPrimary(isDark),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(fontFamily: _fontFamily, 
          color: AppColors.textSecondary(isDark),
          fontSize: 13,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurfaceElevated,
        contentTextStyle: const TextStyle(fontFamily: _fontFamily, 
            color: AppColors.darkTextPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusMedium)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMedium),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkBorderSubtle,
        labelStyle: TextStyle(fontFamily: _fontFamily, 
          color: AppColors.textSecondary(isDark),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(color: AppColors.border(isDark)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusSmall),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  static ThemeService get instance => _instance;

  ThemeMode _themeMode = ThemeMode.system;

  ThemeService._internal() {
    _loadPreference();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  bool isDark(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _savePreference(mode);
    notifyListeners();
  }

  void toggleTheme(BuildContext context) {
    final currentlyDark = isDark(context);
    setThemeMode(currentlyDark ? ThemeMode.light : ThemeMode.dark);
  }

  void _loadPreference() {
    if (kIsWeb) return;
    try {
      final file = File('.theme_mode');
      if (file.existsSync()) {
        final content = file.readAsStringSync().trim();
        if (content == 'dark') {
          _themeMode = ThemeMode.dark;
        } else if (content == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  void _savePreference(ThemeMode mode) {
    if (kIsWeb) return;
    try {
      final file = File('.theme_mode');
      final name = mode == ThemeMode.dark
          ? 'dark'
          : (mode == ThemeMode.light ? 'light' : 'system');
      file.writeAsStringSync(name);
    } catch (_) {}
  }
}

import 'package:flutter/material.dart';

/// The app has a single light theme. This service stays so existing screens
/// that listen to it keep compiling; it never switches to dark.
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  static ThemeService get instance => _instance;

  ThemeService._internal();

  ThemeMode get themeMode => ThemeMode.light;
  bool get isDarkMode => false;

  bool isDark(BuildContext context) => false;
}

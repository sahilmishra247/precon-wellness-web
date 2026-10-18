import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'session_manager.dart';

class ApiConfig {
  static const String _keyCustomBaseUrl = 'app_custom_base_url';

  // Compile-time environment defines
  // Run with: flutter run --dart-define=API_URL=https://api.preconwellness.com --dart-define=FLAVOR=prod
  static const String _envApiUrl = String.fromEnvironment('API_URL', defaultValue: '');
  static const String _envFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static String? _customBaseUrl;

  // Detected host Wi-Fi/LAN IP address for physical phones on local network
  static const String hostIp = '172.20.28.159';

  /// Whether current build is targeting production environment
  static bool get isProduction =>
      _envFlavor.toLowerCase() == 'prod' || _envFlavor.toLowerCase() == 'production';

  /// Active environment flavor name ('dev', 'staging', 'prod')
  static String get flavor => _envFlavor;

  /// Initialize persistent configuration from SharedPreferences on app launch
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_keyCustomBaseUrl);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _customBaseUrl = savedUrl;
      }
    } catch (_) {}
  }

  static String get defaultBaseUrl {
    // 1. If compile-time API_URL is supplied via --dart-define, prioritize it
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }

    // 2. In production release builds, default to the live cloud backend
    if (kReleaseMode) {
      return 'https://precon-backend.onrender.com';
    }

    // 3. In local development / debug builds, route to local server
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        // When connected via USB with adb reverse, 127.0.0.1 routes to host backend
        return 'http://127.0.0.1:8000';
      default:
        // Windows, macOS, Linux desktop
        return 'http://127.0.0.1:8000';
    }
  }


  static String get baseUrl => _customBaseUrl ?? defaultBaseUrl;

  static Future<void> setBaseUrl(String url) async {
    _customBaseUrl = url.trim();
    _dioInstance = null; // Recreate dio instance with new base URL
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCustomBaseUrl, _customBaseUrl!);
    } catch (_) {}
  }

  static Future<void> resetBaseUrl() async {
    _customBaseUrl = null;
    _dioInstance = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCustomBaseUrl);
    } catch (_) {}
  }

  static Future<bool> testConnection(String url) async {
    try {
      final cleanUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
      final testDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final res = await testDio.get('$cleanUrl/docs');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Dio? _dioInstance;

  static Dio get dio {
    if (_dioInstance == null) {
      final instance = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {

            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Add transparent JWT Bearer token authentication & error handling
      instance.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final token = SessionManager.token;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (DioException e, handler) {
            if (e.response?.statusCode == 401) {
              debugPrint('[API Auth] 401 Unauthorized for ${optionsUri(e.requestOptions)}');
            }
            return handler.next(e);
          },
        ),
      );

      _dioInstance = instance;
    }
    return _dioInstance!;
  }

  static String optionsUri(RequestOptions options) {
    return '${options.baseUrl}${options.path}';
  }
}


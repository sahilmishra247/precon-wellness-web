import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';

class SessionManager {
  static const _keyUserId = 'auth_user_id';
  static const _keyName = 'auth_name';
  static const _keyEmail = 'auth_email';
  static const _keyRole = 'auth_role';
  static const _keyToken = 'auth_jwt_token';
  static const _keyClientJson = 'auth_client_json';

  static int? userId;
  static String? name;
  static String? email;
  static String? role;
  static String? token;
  static Client? client;

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    userId = _prefs?.getInt(_keyUserId);
    name = _prefs?.getString(_keyName);
    email = _prefs?.getString(_keyEmail);
    role = _prefs?.getString(_keyRole);
    token = _prefs?.getString(_keyToken);

    final clientJsonStr = _prefs?.getString(_keyClientJson);
    if (clientJsonStr != null && clientJsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(clientJsonStr);
        client = Client.fromJson(decoded);
      } catch (_) {
        client = null;
      }
    }
  }

  static Future<void> setUser({
    required int id,
    required String userName,
    required String userEmail,
    required String userRole,
    String? jwtToken,
    Client? clientData,
  }) async {
    userId = id;
    name = userName;
    email = userEmail;
    role = userRole;
    if (jwtToken != null && jwtToken.isNotEmpty) {
      token = jwtToken;
    }
    client = clientData;

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setInt(_keyUserId, id);
    await _prefs?.setString(_keyName, userName);
    await _prefs?.setString(_keyEmail, userEmail);
    await _prefs?.setString(_keyRole, userRole);
    if (jwtToken != null && jwtToken.isNotEmpty) {
      await _prefs?.setString(_keyToken, jwtToken);
    }

    if (clientData != null) {
      await _prefs?.setString(_keyClientJson, jsonEncode(clientData.toJson()));
    } else {
      await _prefs?.remove(_keyClientJson);
    }
  }

  static Future<void> clear() async {
    userId = null;
    name = null;
    email = null;
    role = null;
    token = null;
    client = null;

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyName);
    await _prefs?.remove(_keyEmail);
    await _prefs?.remove(_keyRole);
    await _prefs?.remove(_keyToken);
    await _prefs?.remove(_keyClientJson);
  }

  static bool get isLoggedIn => userId != null && email != null && role != null;
}
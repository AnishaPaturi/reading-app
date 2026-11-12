import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart';
import 'session_storage_interface.dart';

class IoAuthSessionStorage implements AuthSessionStorage {
  static const String _tokenKey = 'sanctuary_auth_token';
  static const String _userKey = 'sanctuary_auth_user';

  @override
  Future<void> saveSession({required String token, required AuthUser user}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving session to persistent storage: $e');
    }
  }

  @override
  Future<AuthSessionData?> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);
      if (token == null || token.isEmpty || userJson == null || userJson.isEmpty) {
        return null;
      }
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = AuthUser.fromJson(userMap);
      return AuthSessionData(token: token, user: user);
    } catch (e) {
      debugPrint('Error loading session from persistent storage: $e');
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Error clearing session from persistent storage: $e');
    }
  }
}

AuthSessionStorage createPlatformSessionStorage() => IoAuthSessionStorage();

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import '../models/auth_user.dart';
import 'session_storage_interface.dart';

class WebAuthSessionStorage implements AuthSessionStorage {
  static const String _tokenKey = 'sanctuary_auth_token';
  static const String _userKey = 'sanctuary_auth_user';

  @override
  Future<void> saveSession({required String token, required AuthUser user}) async {
    try {
      web.window.sessionStorage.setItem(_tokenKey, token);
      web.window.sessionStorage.setItem(_userKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving session to web sessionStorage: $e');
    }
  }

  @override
  Future<AuthSessionData?> loadSession() async {
    try {
      final token = web.window.sessionStorage.getItem(_tokenKey);
      final userJson = web.window.sessionStorage.getItem(_userKey);
      if (token == null || token.isEmpty || userJson == null || userJson.isEmpty) {
        return null;
      }
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = AuthUser.fromJson(userMap);
      return AuthSessionData(token: token, user: user);
    } catch (e) {
      debugPrint('Error loading session from web sessionStorage: $e');
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      web.window.sessionStorage.removeItem(_tokenKey);
      web.window.sessionStorage.removeItem(_userKey);
    } catch (e) {
      debugPrint('Error clearing session from web sessionStorage: $e');
    }
  }
}

AuthSessionStorage createPlatformSessionStorage() => WebAuthSessionStorage();

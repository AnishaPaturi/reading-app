// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import 'session_storage_interface.dart';

class WebAuthSessionStorage implements AuthSessionStorage {
  static const String _tokenKey = 'sanctuary_auth_token';
  static const String _userKey = 'sanctuary_auth_user';

  @override
  Future<void> saveSession({required String token, required AuthUser user}) async {
    try {
      html.window.sessionStorage[_tokenKey] = token;
      html.window.sessionStorage[_userKey] = jsonEncode(user.toJson());
    } catch (e) {
      debugPrint('Error saving session to web sessionStorage: $e');
    }
  }

  @override
  Future<AuthSessionData?> loadSession() async {
    try {
      final token = html.window.sessionStorage[_tokenKey];
      final userJson = html.window.sessionStorage[_userKey];
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
      html.window.sessionStorage.remove(_tokenKey);
      html.window.sessionStorage.remove(_userKey);
    } catch (e) {
      debugPrint('Error clearing session from web sessionStorage: $e');
    }
  }
}

AuthSessionStorage createPlatformSessionStorage() => WebAuthSessionStorage();

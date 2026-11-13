import '../models/auth_user.dart';

class AuthSessionData {
  final String token;
  final AuthUser user;

  const AuthSessionData({required this.token, required this.user});
}

abstract class AuthSessionStorage {
  Future<void> saveSession({required String token, required AuthUser user});
  Future<AuthSessionData?> loadSession();
  Future<void> clearSession();
}

/// Fallback / Test implementation that keeps session in-memory only.
class InMemoryAuthSessionStorage implements AuthSessionStorage {
  String? _token;
  AuthUser? _user;

  @override
  Future<void> saveSession({required String token, required AuthUser user}) async {
    _token = token;
    _user = user;
  }

  @override
  Future<AuthSessionData?> loadSession() async {
    if (_token != null && _token!.isNotEmpty && _user != null) {
      return AuthSessionData(token: _token!, user: _user!);
    }
    return null;
  }

  @override
  Future<void> clearSession() async {
    _token = null;
    _user = null;
  }
}

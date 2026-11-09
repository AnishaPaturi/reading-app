import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      if (_envBaseUrl.endsWith('/api/v1')) return _envBaseUrl;
      if (_envBaseUrl.endsWith('/')) return '${_envBaseUrl}api/v1';
      return '$_envBaseUrl/api/v1';
    }

    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080/api/v1';
    return 'http://localhost:8080/api/v1';
  }

  static const Duration timeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
}

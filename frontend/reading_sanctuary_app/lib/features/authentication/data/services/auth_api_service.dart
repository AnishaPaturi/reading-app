import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/auth_user.dart';

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/auth/login',
        body: {
          'email': email.trim(),
          'password': password,
        },
      );

      if (response is Map<String, dynamic>) {
        return AuthUser.fromJson(response);
      }
      throw const ApiException(message: 'Invalid response from server', statusCode: 500);
    } on NetworkException catch (e) {
      debugPrint('AuthApiService: Network error ($e). Demo fallback active if needed.');
      // If server is not running locally, provide friendly fallback for immediate dev preview
      if (kDebugMode && (email.contains('@') && password.length >= 6)) {
        return AuthUser(
          id: 'demo-user-123',
          email: email,
          token: 'demo-mock-jwt-token',
          displayName: email.split('@').first,
        );
      }
      rethrow;
    }
  }

  Future<AuthUser> register({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/v1/users',
        body: {
          'email': email.trim(),
          'password': password,
        },
      );

      // After registration, auto-login or return user
      if (response is Map<String, dynamic>) {
        final userId = response['id']?.toString() ?? 'new-user';
        return AuthUser(
          id: userId,
          email: email.trim(),
          token: response['accessToken']?.toString() ?? 'registered-token',
          displayName: username ?? email.split('@').first,
        );
      }
      throw const ApiException(message: 'Failed to create user account', statusCode: 500);
    } on NetworkException catch (e) {
      debugPrint('AuthApiService: Network error ($e). Demo fallback active if needed.');
      if (kDebugMode && (email.contains('@') && password.length >= 6)) {
        return AuthUser(
          id: 'demo-user-registered',
          email: email,
          token: 'demo-mock-jwt-token',
          displayName: username ?? email.split('@').first,
        );
      }
      rethrow;
    }
  }
}

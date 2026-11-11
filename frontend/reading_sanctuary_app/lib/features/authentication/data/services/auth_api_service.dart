import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/auth_user.dart';

class AuthApiService {
  final ApiClient _apiClient;
  AuthApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<AuthUser> login({required String email, required String password}) async {
    final response = await _apiClient.post('/auth/login', body: {
      'email': email.trim(), 'password': password,
    });
    if (response is Map<String, dynamic>) return AuthUser.fromJson(response);
    throw const ApiException(message: 'Invalid response from server', statusCode: 500);
  }

  Future<AuthUser> loginWithGoogle({required String idToken}) async {
    final response = await _apiClient.post('/auth/google', body: {'idToken': idToken});
    if (response is Map<String, dynamic>) return AuthUser.fromJson(response);
    throw const ApiException(message: 'Invalid response from server', statusCode: 500);
  }

  Future<AuthUser> register({
    required String email, required String password, String? username, String? gender,
  }) async {
    final response = await _apiClient.post('/users/register', body: {
      'email': email.trim(), 'password': password,
      if (username != null && username.trim().isNotEmpty) 'displayName': username.trim(),
      if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
    });
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Failed to create user account', statusCode: 500);
    }
    final loggedInUser = await login(email: email, password: password);
    if (gender != null && gender.trim().isNotEmpty) {
      return loggedInUser.copyWith(gender: gender.trim());
    }
    return loggedInUser;
  }
}

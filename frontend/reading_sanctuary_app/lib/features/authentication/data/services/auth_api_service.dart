import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/auth_user.dart';

class AuthApiService {
  final ApiClient _apiClient;
  AuthApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<AuthUser> login({required String email, required String password}) async {
    final response = await _apiClient.post('/auth/login', body: {
      'email': email.trim(),
      'password': password.trim(),
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
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    final response = await _apiClient.post('/users/register', body: {
      'email': trimmedEmail,
      'password': trimmedPassword,
      if (username != null && username.trim().isNotEmpty) 'displayName': username.trim(),
      if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
    });
    if (response is! Map<String, dynamic>) {
      throw const ApiException(message: 'Failed to create user account', statusCode: 500);
    }
    final loggedInUser = await login(email: trimmedEmail, password: trimmedPassword);
    if (gender != null && gender.trim().isNotEmpty) {
      return loggedInUser.copyWith(gender: gender.trim());
    }
    return loggedInUser;
  }

  Future<AuthUser> fetchUserProfile() async {
    final response = await _apiClient.get('/users/me');
    if (response is Map<String, dynamic>) return AuthUser.fromJson(response);
    throw const ApiException(message: 'Failed to fetch user profile', statusCode: 500);
  }

  Future<AuthUser> updateProfile({required String displayName}) async {
    final response = await _apiClient.patch('/users/me', body: {'displayName': displayName.trim()});
    if (response is Map<String, dynamic>) return AuthUser.fromJson(response);
    throw const ApiException(message: 'Failed to update profile', statusCode: 500);
  }

  Future<AuthUser> setGender(String gender) async {
    final response = await _apiClient.patch('/users/me/gender', body: {'gender': gender});
    if (response is Map<String, dynamic>) return AuthUser.fromJson(response);
    throw const ApiException(message: 'Failed to set gender', statusCode: 500);
  }
}

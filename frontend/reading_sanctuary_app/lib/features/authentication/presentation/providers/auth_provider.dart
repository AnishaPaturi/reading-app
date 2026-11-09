import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../reader/presentation/providers/reader_provider.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_api_service.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final AuthUser? user;

  const AuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  bool get isAuthenticated => user != null && (user!.token?.isNotEmpty ?? false);

  AuthState copyWith({
    bool? isLoading,
    String? error,
    AuthUser? user,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _apiService;
  final StateController<String?> _tokenNotifier;

  AuthNotifier({
    required AuthApiService apiService,
    required StateController<String?> tokenNotifier,
  })  : _apiService = apiService,
        _tokenNotifier = tokenNotifier,
        super(const AuthState());

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _apiService.login(email: email, password: password);
      _tokenNotifier.state = user.token;
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? username,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _apiService.register(
        email: email,
        password: password,
        username: username,
      );
      _tokenNotifier.state = user.token;
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      return false;
    }
  }

  Future<bool> loginWithSocial(String provider) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 600));
    final mockUser = AuthUser(
      id: 'social-$provider-user',
      email: 'user@$provider.com',
      token: 'mock-$provider-token',
      displayName: '$provider User',
    );
    _tokenNotifier.state = mockUser.token;
    state = state.copyWith(isLoading: false, user: mockUser);
    return true;
  }

  void logout() {
    _tokenNotifier.state = null;
    state = const AuthState();
  }

  String _extractErrorMessage(dynamic e) {
    final msg = e.toString();
    if (msg.contains('Exception:')) {
      return msg.split('Exception:').last.trim();
    }
    return msg;
  }
}

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthApiService(apiClient: apiClient);
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(authApiServiceProvider);
  final tokenNotifier = ref.watch(authTokenProvider.notifier);
  return AuthNotifier(
    apiService: apiService,
    tokenNotifier: tokenNotifier,
  );
});

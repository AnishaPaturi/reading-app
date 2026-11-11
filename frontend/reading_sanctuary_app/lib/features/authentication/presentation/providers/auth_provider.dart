import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/network/network_providers.dart';
import '../../../reader/presentation/providers/reader_provider.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_api_service.dart';

class AuthState {
  final bool isLoading;
  final String? error;
  final AuthUser? user;

  const AuthState({this.isLoading = false, this.error, this.user});
  bool get isAuthenticated => user != null && (user!.token?.isNotEmpty ?? false);

  AuthState copyWith({bool? isLoading, String? error, AuthUser? user,
      bool clearError = false}) => AuthState(
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),
    user: user ?? this.user,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _apiService;
  final StateController<String?> _tokenNotifier;
  final GoogleSignIn _googleSignIn;

  AuthNotifier({required AuthApiService apiService,
      required StateController<String?> tokenNotifier,
      required GoogleSignIn googleSignIn})
      : _apiService = apiService,
        _tokenNotifier = tokenNotifier,
        _googleSignIn = googleSignIn,
        super(const AuthState());

  void clearError() => state = state.copyWith(clearError: true);

  void setGender(String gender) {
    if (state.user != null) {
      state = state.copyWith(user: state.user!.copyWith(gender: gender));
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _apiService.login(email: email, password: password);
      _tokenNotifier.state = user.token;
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> register({required String email, required String password,
      String? username, String? gender}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _apiService.register(
          email: email, password: password, username: username, gender: gender);
      _tokenNotifier.state = user.token;
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> loginWithSocial(String provider) async {
    if (provider.toLowerCase() != 'google') {
      state = state.copyWith(isLoading: false, error: '$provider sign-in is not configured yet.');
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // The user closed the Google account picker.
        state = state.copyWith(isLoading: false);
        return false;
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return an ID token. Check your OAuth client configuration.');
      }

      // Only the ID token goes to the API. The backend verifies it with Google.
      final user = await _apiService.loginWithGoogle(idToken: idToken);
      if (user.token == null || user.token!.isEmpty) {
        throw Exception('The server did not return a Reading Sanctuary session.');
      }

      _tokenNotifier.state = user.token;
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Local logout must still complete if Google sign-out is unavailable.
    }
    _tokenNotifier.state = null;
    state = const AuthState();
  }

  String _extractErrorMessage(dynamic e) {
    final msg = e.toString();
    if (msg.contains('Exception:')) return msg.split('Exception:').last.trim();
    return msg;
  }
}

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  const webClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: webClientId.isEmpty ? null : webClientId,
  );
});

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(apiClient: ref.watch(apiClientProvider));
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    apiService: ref.watch(authApiServiceProvider),
    tokenNotifier: ref.watch(authTokenProvider.notifier),
    googleSignIn: ref.watch(googleSignInProvider),
  );
});

/// Avatar gender provider: 'girl' (default) or 'boy'.
/// Normalizes 'male' -> 'boy', 'female' -> 'girl'.
final userGenderProvider = StateProvider<String>((ref) {
  final authUser = ref.watch(authNotifierProvider).user;
  final g = authUser?.gender?.toLowerCase();
  if (g == 'male' || g == 'boy') return 'boy';
  return 'girl';
});

/// Centralized provider for the animated character avatar image path.
/// Automatically updates throughout the app based on selected gender.
final userAvatarAssetProvider = Provider<String>((ref) {
  final gender = ref.watch(userGenderProvider);
  if (gender == 'boy') {
    return 'assets/images/dashboard/avatar_boy.png';
  }
  return 'assets/images/dashboard/avatar_mia.png';
});

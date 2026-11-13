import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/network_providers.dart';
import '../../../reader/presentation/providers/reader_provider.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_api_service.dart';
import '../../data/services/session_storage.dart';

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
  final AuthSessionStorage _sessionStorage;

  AuthNotifier({
    required AuthApiService apiService,
    required StateController<String?> tokenNotifier,
    required GoogleSignIn googleSignIn,
    required AuthSessionStorage sessionStorage,
  })  : _apiService = apiService,
        _tokenNotifier = tokenNotifier,
        _googleSignIn = googleSignIn,
        _sessionStorage = sessionStorage,
        super(const AuthState());

  void clearError() => state = state.copyWith(clearError: true);

  /// Restores session on app startup if a valid stored session is found.
  /// - On mobile: Restores persistent session saved in SharedPreferences.
  /// - On web: Restores session if the browser tab/window session exists.
  Future<bool> restoreSession() async {
    try {
      final session = await _sessionStorage.loadSession();
      if (session != null && session.token.isNotEmpty) {
        _tokenNotifier.state = session.token;
        state = state.copyWith(user: session.user, isLoading: false);
        // Silently refresh profile in the background from database
        refreshUserProfile();
      }
      final prefs = await SharedPreferences.getInstance();
      final customName = prefs.getString('sanctuary_user_display_name');
      if (customName != null && customName.isNotEmpty) {
        if (state.user != null) {
          state = state.copyWith(user: state.user!.copyWith(displayName: customName));
        } else {
          state = state.copyWith(
            user: AuthUser(id: 'local_user', email: '', displayName: customName),
          );
        }
      }
      if (session != null && session.token.isNotEmpty) return true;
    } catch (_) {
      // Gracefully continue without session if loading fails
    }
    return false;
  }

  /// Sets user gender. Once set, gender is permanent and cannot be switched.
  Future<bool> setGender(String gender) async {
    if (state.user != null) {
      // Once gender is set, switching is not allowed
      if (state.user!.gender != null && state.user!.gender!.trim().isNotEmpty) {
        return false;
      }
      final normalized = (gender.toLowerCase() == 'male' || gender.toLowerCase() == 'boy')
          ? 'boy'
          : 'girl';
      final updatedUser = state.user!.copyWith(gender: normalized);
      state = state.copyWith(user: updatedUser);
      if (updatedUser.token != null && updatedUser.token!.isNotEmpty) {
        await _sessionStorage.saveSession(token: updatedUser.token!, user: updatedUser);
        try {
          await _apiService.setGender(normalized);
        } catch (_) {}
      }
      return true;
    }
    return false;
  }

  /// Updates user display name and persists to database, session storage, and local preferences.
  Future<bool> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sanctuary_user_display_name', trimmed);
    } catch (_) {}

    final token = _tokenNotifier.state;
    if (state.user != null) {
      final updated = state.user!.copyWith(displayName: trimmed);
      state = state.copyWith(user: updated);
      if (token != null && token.isNotEmpty) {
        await _sessionStorage.saveSession(token: token, user: updated);
        try {
          await _apiService.updateProfile(displayName: trimmed);
        } catch (_) {}
      }
      return true;
    } else {
      final localUser = AuthUser(id: 'local_user', email: '', displayName: trimmed);
      state = state.copyWith(user: localUser);
      return true;
    }
  }

  /// Refreshes user profile directly from database (/api/v1/users/me).
  Future<void> refreshUserProfile() async {
    final token = _tokenNotifier.state;
    if (token == null || token.isEmpty) return;
    try {
      final fetched = await _apiService.fetchUserProfile();
      final current = state.user;
      final merged = fetched.copyWith(
        token: token,
        gender: (fetched.gender != null && fetched.gender!.isNotEmpty)
            ? fetched.gender
            : current?.gender,
      );
      state = state.copyWith(user: merged);
      await _sessionStorage.saveSession(token: token, user: merged);
    } catch (_) {
      // Fallback gracefully to existing session
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _apiService.login(email: email, password: password);
      _tokenNotifier.state = user.token;
      state = state.copyWith(isLoading: false, user: user);
      if (user.token != null && user.token!.isNotEmpty) {
        await _sessionStorage.saveSession(token: user.token!, user: user);
      }
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
      if (user.token != null && user.token!.isNotEmpty) {
        await _sessionStorage.saveSession(token: user.token!, user: user);
      }
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
      await _sessionStorage.saveSession(token: user.token!, user: user);
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
    await _sessionStorage.clearSession();
    _tokenNotifier.state = null;
    state = const AuthState();
  }

  String _extractErrorMessage(dynamic e) {
    if (e is ApiException) return e.message;
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
    sessionStorage: ref.watch(authSessionStorageProvider),
  );
});

/// Avatar gender provider: 'girl' (default) or 'boy'.
/// Normalizes 'male' -> 'boy', 'female' -> 'girl'.
final userGenderProvider = StateProvider<String>((ref) {
  final authUser = ref.watch(authNotifierProvider).user;
  final g = authUser?.gender?.toLowerCase();
  if (g == 'male' || g == 'boy') return 'boy';
  if (g == 'female' || g == 'girl') return 'girl';
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

/// Centralized provider for the dashboard hero banner image path.
/// Automatically updates throughout the app based on selected gender:
/// - 'girl': assets/images/dashboard/dash_banner.png (animated girl reading)
/// - 'boy': assets/images/dashboard/dash_banner_boy.png (animated boy reading)
final userBannerAssetProvider = Provider<String>((ref) {
  final gender = ref.watch(userGenderProvider);
  if (gender == 'boy') {
    return 'assets/images/dashboard/dash_banner_boy.png';
  }
  return 'assets/images/dashboard/dash_banner.png';
});

class CustomDisplayNameNotifier extends StateNotifier<String?> {
  static const _key = 'sanctuary_user_display_name';

  CustomDisplayNameNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (saved != null && saved.trim().isNotEmpty) {
        state = saved.trim();
      }
    } catch (_) {}
  }

  Future<void> setName(String name) async {
    final trimmed = name.trim();
    state = trimmed;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, trimmed);
    } catch (_) {}
  }
}

final customDisplayNameProvider =
    StateNotifierProvider<CustomDisplayNameNotifier, String?>((ref) {
  return CustomDisplayNameNotifier();
});

/// Resolves the user's friendly display name across the application.
final userDisplayNameProvider = Provider<String>((ref) {
  final customName = ref.watch(customDisplayNameProvider);
  if (customName != null && customName.trim().isNotEmpty) {
    return customName.trim();
  }
  final authUser = ref.watch(authNotifierProvider).user;
  final rawName = authUser?.displayName?.trim();
  if (rawName != null && rawName.isNotEmpty && rawName.toLowerCase() != 'reader') {
    return rawName;
  }
  final email = authUser?.email ?? '';
  final emailPrefix = email.contains('@') ? email.split('@').first : email;
  if (emailPrefix.isNotEmpty && emailPrefix.toLowerCase() != 'reader') {
    return emailPrefix[0].toUpperCase() + (emailPrefix.length > 1 ? emailPrefix.substring(1) : '');
  }
  return 'Reader';
});

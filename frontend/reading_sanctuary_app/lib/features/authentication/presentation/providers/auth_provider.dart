import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

class GoogleSignInManager {
  static GoogleSignIn? _singleton;
  static String? _singletonKey;

  static GoogleSignIn resolve({
    required String clientId,
    String? serverClientId,
    List<String> scopes = const ['email', 'profile'],
  }) {
    final key = '$clientId|${serverClientId ?? ''}|${scopes.join(',')}';
    if (_singleton != null && _singletonKey == key) {
      return _singleton!;
    }
    _singleton = GoogleSignIn(
      clientId: clientId,
      serverClientId: serverClientId,
      scopes: scopes,
    );
    _singletonKey = key;
    return _singleton!;
  }

  @visibleForTesting
  static void resetForTesting() {
    _singleton = null;
    _singletonKey = null;
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _apiService;
  final StateController<String?> _tokenNotifier;
  final GoogleSignIn? _injectedGoogleSignIn;
  final GoogleSignIn Function()? _googleSignInFactory;
  final AuthSessionStorage _sessionStorage;
  final StateController<bool>? _sessionRestoredNotifier;
  final StateController<bool>? _sessionExpiredNotifier;
  GoogleSignIn? _resolvedGoogleSignIn;
  Future<bool>? _restoreFuture;

  AuthNotifier({
    required AuthApiService apiService,
    required StateController<String?> tokenNotifier,
    GoogleSignIn? googleSignIn,
    GoogleSignIn Function()? googleSignInFactory,
    required AuthSessionStorage sessionStorage,
    StateController<bool>? sessionRestoredNotifier,
    StateController<bool>? sessionExpiredNotifier,
  })  : assert(
          googleSignIn != null || googleSignInFactory != null,
          'Either googleSignIn or googleSignInFactory must be provided.',
        ),
        _apiService = apiService,
        _tokenNotifier = tokenNotifier,
        _injectedGoogleSignIn = googleSignIn,
        _googleSignInFactory = googleSignInFactory,
        _sessionStorage = sessionStorage,
        _sessionRestoredNotifier = sessionRestoredNotifier,
        _sessionExpiredNotifier = sessionExpiredNotifier,
        super(const AuthState());

  GoogleSignIn get _googleSignIn =>
      _resolvedGoogleSignIn ??= (_injectedGoogleSignIn ?? _googleSignInFactory!());

  void clearError() => state = state.copyWith(clearError: true);

  /// Restores session on app startup if a valid stored session is found.
  /// Deduplicates concurrent or repeated startup restore calls.
  Future<bool> restoreSession() {
    return _restoreFuture ??= _performRestoreSession();
  }

  Future<bool> _performRestoreSession() async {
    try {
      final session = await _sessionStorage.loadSession();

      if (!mounted) return false;

      if (session != null && session.token.isNotEmpty) {
        _tokenNotifier.state = session.token;
        _sessionExpiredNotifier?.state = false;

        state = state.copyWith(
          user: session.user.copyWith(token: session.token),
          isLoading: false,
        );

        // Validate session token before protected routes mount and start API requests.
        await refreshUserProfile();
        if (!mounted) return false;

        _sessionRestoredNotifier?.state = true;
        return state.isAuthenticated;
      }
    } catch (_) {
      if (!mounted) return false;
    }

    if (!mounted) return false;

    _tokenNotifier.state = null;
    state = const AuthState();
    _sessionRestoredNotifier?.state = true;
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

  /// Updates user display name and persists to database and session storage.
  Future<bool> updateDisplayName(String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return false;

    final token = _tokenNotifier.state;
    if (state.user != null && state.isAuthenticated) {
      final updated = state.user!.copyWith(displayName: trimmed);
      state = state.copyWith(user: updated);
      if (token != null && token.isNotEmpty) {
        await _sessionStorage.saveSession(token: token, user: updated);
        try {
          await _apiService.updateProfile(displayName: trimmed);
        } catch (_) {}
      }
      return true;
    }
    return false;
  }

  /// Refreshes user profile directly from database (/api/v1/users/me).
  Future<void> refreshUserProfile() async {
    final token = _tokenNotifier.state;

    if (token == null || token.isEmpty) return;

    try {
      final fetched = await _apiService.fetchUserProfile();

      // The notifier may have been disposed during the request.
      if (!mounted) return;

      final current = state.user;

      final merged = fetched.copyWith(
        token: token,
        displayName: (fetched.displayName != null &&
                fetched.displayName!.trim().isNotEmpty &&
                fetched.displayName!.trim().toLowerCase() != 'reader')
            ? fetched.displayName
            : current?.displayName,
        gender: (fetched.gender != null && fetched.gender!.isNotEmpty)
            ? fetched.gender
            : current?.gender,
      );

      state = state.copyWith(user: merged);

      await _sessionStorage.saveSession(
        token: token,
        user: merged,
      );

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;

      if (e is UnauthorizedException) {
        await _sessionStorage.clearSession();

        if (!mounted) return;

        _tokenNotifier.state = null;
        _restoreFuture = Future.value(false);
        _sessionExpiredNotifier?.state = true;
        state = const AuthState();
        _sessionRestoredNotifier?.state = true;
      }
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authUser = await _apiService.login(email: email, password: password);
      if (!mounted) return false;

      final token = authUser.token;
      _tokenNotifier.state = token;

      AuthUser authoritativeUser = authUser;
      if (token != null && token.isNotEmpty) {
        try {
          final profile = await _apiService.fetchUserProfile();
          if (!mounted) return false;
          authoritativeUser = profile.copyWith(
            token: token,
            gender: (profile.gender != null && profile.gender!.isNotEmpty)
                ? profile.gender
                : authUser.gender,
          );
        } catch (_) {
          // Fall back to login response if /users/me is unreachable
        }
        await _sessionStorage.saveSession(token: token, user: authoritativeUser);
        if (!mounted) return false;
      }

      _restoreFuture = Future.value(true);
      _sessionExpiredNotifier?.state = false;
      _sessionRestoredNotifier?.state = true;
      state = state.copyWith(isLoading: false, user: authoritativeUser);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? username,
    String? gender,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authUser = await _apiService.register(
        email: email,
        password: password,
        username: username,
        gender: gender,
      );
      if (!mounted) return false;

      final token = authUser.token;
      _tokenNotifier.state = token;

      AuthUser authoritativeUser = authUser;
      if (token != null && token.isNotEmpty) {
        try {
          final profile = await _apiService.fetchUserProfile();
          if (!mounted) return false;
          authoritativeUser = profile.copyWith(
            token: token,
            gender: (profile.gender != null && profile.gender!.isNotEmpty)
                ? profile.gender
                : (authUser.gender ?? gender),
          );
        } catch (_) {
          // Fall back to register response if /users/me is unreachable
        }
        await _sessionStorage.saveSession(token: token, user: authoritativeUser);
        if (!mounted) return false;
      }

      _restoreFuture = Future.value(true);
      _sessionExpiredNotifier?.state = false;
      _sessionRestoredNotifier?.state = true;
      state = state.copyWith(isLoading: false, user: authoritativeUser);
      return true;
    } catch (e) {
      if (!mounted) return false;
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
      // Clear any prior cached session on mobile so Google Play Services
      // re-prompts or fetches fresh tokens with the serverClientId audience.
      if (!kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }

      final account = await _googleSignIn.signIn();
      if (!mounted) return false;
      if (account == null) {
        // The user closed the Google account picker.
        state = state.copyWith(isLoading: false);
        return false;
      }

      final googleAuth = await account.authentication;
      if (!mounted) return false;

      final token = (googleAuth.idToken != null && googleAuth.idToken!.isNotEmpty)
          ? googleAuth.idToken
          : googleAuth.accessToken;

      if (token == null || token.isEmpty) {
        throw Exception('Google did not return an authentication token. Check your Google account settings.');
      }

      // Backend verifies either the ID token JWT or access token with Google.
      final authUser = await _apiService.loginWithGoogle(idToken: token);
      if (!mounted) return false;

      if (authUser.token == null || authUser.token!.isEmpty) {
        throw Exception('The server did not return a Reading Sanctuary session.');
      }

      final sessionToken = authUser.token!;
      _tokenNotifier.state = sessionToken;

      AuthUser authoritativeUser = authUser;
      try {
        final profile = await _apiService.fetchUserProfile();
        if (!mounted) return false;
        authoritativeUser = profile.copyWith(
          token: sessionToken,
          gender: (profile.gender != null && profile.gender!.isNotEmpty)
              ? profile.gender
              : authUser.gender,
        );
      } catch (_) {
        // Fall back to Google login auth response if /users/me is unreachable
      }

      await _sessionStorage.saveSession(token: sessionToken, user: authoritativeUser);
      if (!mounted) return false;

      _restoreFuture = Future.value(true);
      _sessionExpiredNotifier?.state = false;
      _sessionRestoredNotifier?.state = true;
      state = state.copyWith(isLoading: false, user: authoritativeUser);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, error: _extractErrorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    // On Web, avoid initializing Google Identity Services on logout if Google Sign-In
    // was never initialized in this session; on native platforms, clear any cached account.
    if (!kIsWeb || _resolvedGoogleSignIn != null || _injectedGoogleSignIn != null) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Local logout must still complete if Google sign-out is unavailable.
      }
    }
    await _sessionStorage.clearSession();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('sanctuary_user_display_name');
    } catch (_) {}
    _tokenNotifier.state = null;
    _restoreFuture = null;
    _sessionExpiredNotifier?.state = false;
    _sessionRestoredNotifier?.state = true;
    if (!mounted) return;
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
  final webClientId = dotenv.isInitialized
      ? dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim()
      : null;

  final serverClientId = dotenv.isInitialized
      ? dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim()
      : null;

  final effectiveClientId = (webClientId != null && webClientId.isNotEmpty)
      ? webClientId
      : 'dummy_web_client_id';

  return GoogleSignInManager.resolve(
    clientId: effectiveClientId,

    // Google Sign-In Web does not support serverClientId.
    serverClientId: kIsWeb
        ? null
        : ((serverClientId == null || serverClientId.isEmpty)
            ? effectiveClientId
            : serverClientId),

    scopes: const [
      'email',
      'profile',
    ],
  );
});

final authSessionRestoredProvider = StateProvider<bool>((ref) => false);

final authSessionExpiredProvider = StateProvider<bool>((ref) => false);

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService(apiClient: ref.watch(apiClientProvider));
});

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    apiService: ref.watch(authApiServiceProvider),

    // Do not subscribe to token state changes here.
    tokenNotifier: ref.read(authTokenProvider.notifier),

    googleSignInFactory: () => ref.read(googleSignInProvider),
    sessionStorage: ref.watch(authSessionStorageProvider),
    sessionRestoredNotifier: ref.read(authSessionRestoredProvider.notifier),
    sessionExpiredNotifier: ref.read(authSessionExpiredProvider.notifier),
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

final userDisplayNameProvider = Provider<String>((ref) {
  final authState = ref.watch(authNotifierProvider);
  final user = authState.user;

  // Never display a previous account's name.
  if (user == null || !authState.isAuthenticated) {
    return 'Reader';
  }

  final name = user.displayName?.trim();

  if (name != null &&
      name.isNotEmpty &&
      name.toLowerCase() != 'reader') {
    return name;
  }

  final email = user.email.trim();

  if (email.contains('@')) {
    final prefix = email.split('@').first;

    if (prefix.isNotEmpty) {
      return prefix[0].toUpperCase() + prefix.substring(1);
    }
  }

  return 'Reader';
});

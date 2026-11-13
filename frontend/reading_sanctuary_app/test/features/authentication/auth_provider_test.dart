import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reading_sanctuary_app/core/network/api_client.dart';
import 'package:reading_sanctuary_app/features/authentication/data/models/auth_user.dart';
import 'package:reading_sanctuary_app/features/authentication/data/services/auth_api_service.dart';
import 'package:reading_sanctuary_app/features/authentication/data/services/session_storage.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:reading_sanctuary_app/features/reader/presentation/providers/reader_provider.dart';

class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService() : super(apiClient: ApiClient(tokenProvider: () => null, baseUrl: ''));

  AuthUser? loginResult;
  AuthUser? registerResult;
  AuthUser? userProfileResult;

  @override
  Future<AuthUser> login({required String email, required String password}) async {
    if (loginResult != null) return loginResult!;
    throw Exception('Login failed');
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    String? username,
    String? gender,
  }) async {
    if (registerResult != null) return registerResult!;
    throw Exception('Registration failed');
  }

  @override
  Future<AuthUser> fetchUserProfile() async {
    if (userProfileResult != null) return userProfileResult!;
    return loginResult ?? registerResult ?? const AuthUser(id: 'me', email: '');
  }

  @override
  Future<AuthUser> updateProfile({required String displayName}) async {
    return AuthUser(id: 'me', email: '', displayName: displayName);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAuthApiService fakeApiService;
  late InMemoryAuthSessionStorage fakeStorage;
  late StateController<String?> tokenController;
  late AuthNotifier authNotifier;

  const sampleUser = AuthUser(
    id: 'user-456',
    email: 'test@sanctuary.app',
    token: 'saved-token-123',
    displayName: 'Sanctuary Reader',
    gender: 'boy',
  );

  setUp(() {
    fakeApiService = FakeAuthApiService();
    fakeStorage = InMemoryAuthSessionStorage();
    tokenController = StateController<String?>(null);
    authNotifier = AuthNotifier(
      apiService: fakeApiService,
      tokenNotifier: tokenController,
      googleSignIn: GoogleSignIn(),
      sessionStorage: fakeStorage,
    );
  });

  group('AuthNotifier Session Persistence Tests', () {
    test('restoreSession restores user and token when session exists in storage', () async {
      await fakeStorage.saveSession(token: sampleUser.token!, user: sampleUser);

      final success = await authNotifier.restoreSession();

      expect(success, isTrue);
      expect(tokenController.state, 'saved-token-123');
      expect(authNotifier.state.user?.id, 'user-456');
      expect(authNotifier.state.user?.displayName, 'Sanctuary Reader');
      expect(authNotifier.state.isAuthenticated, isTrue);
    });

    test('restoreSession returns false when storage is empty', () async {
      final success = await authNotifier.restoreSession();

      expect(success, isFalse);
      expect(tokenController.state, isNull);
      expect(authNotifier.state.user, isNull);
      expect(authNotifier.state.isAuthenticated, isFalse);
    });

    test('login persists session to storage on success', () async {
      fakeApiService.loginResult = sampleUser;

      final success = await authNotifier.login(
        email: 'test@sanctuary.app',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(tokenController.state, 'saved-token-123');
      expect(authNotifier.state.user?.email, 'test@sanctuary.app');

      // Verify persisted in storage
      final stored = await fakeStorage.loadSession();
      expect(stored, isNotNull);
      expect(stored!.token, 'saved-token-123');
      expect(stored.user.id, 'user-456');
    });

    test('register persists session to storage on success', () async {
      fakeApiService.registerResult = sampleUser;

      final success = await authNotifier.register(
        email: 'test@sanctuary.app',
        password: 'password123',
        username: 'Sanctuary Reader',
        gender: 'boy',
      );

      expect(success, isTrue);
      expect(tokenController.state, 'saved-token-123');
      expect(authNotifier.state.user?.gender, 'boy');

      final stored = await fakeStorage.loadSession();
      expect(stored, isNotNull);
      expect(stored!.token, 'saved-token-123');
      expect(stored.user.gender, 'boy');
    });

    test('setGender updates user and session storage when gender is unset', () async {
      final unsetUser = AuthUser(
        id: sampleUser.id,
        email: sampleUser.email,
        token: sampleUser.token,
        displayName: sampleUser.displayName,
        gender: null,
      );
      fakeApiService.loginResult = unsetUser;
      await authNotifier.login(email: 'test@sanctuary.app', password: 'password123');

      final result = await authNotifier.setGender('girl');

      expect(result, isTrue);
      expect(authNotifier.state.user?.gender, 'girl');
      final stored = await fakeStorage.loadSession();
      expect(stored?.user.gender, 'girl');
    });

    test('setGender prevents switching when gender is already set', () async {
      fakeApiService.loginResult = sampleUser; // has gender 'boy'
      await authNotifier.login(email: 'test@sanctuary.app', password: 'password123');

      final result = await authNotifier.setGender('girl');

      expect(result, isFalse);
      expect(authNotifier.state.user?.gender, 'boy');
      final stored = await fakeStorage.loadSession();
      expect(stored?.user.gender, 'boy');
    });

    test('logout clears session from storage and resets state', () async {
      fakeApiService.loginResult = sampleUser;
      await authNotifier.login(email: 'test@sanctuary.app', password: 'password123');
      expect(await fakeStorage.loadSession(), isNotNull);

      await authNotifier.logout();

      expect(tokenController.state, isNull);
      expect(authNotifier.state.user, isNull);
      expect(authNotifier.state.isAuthenticated, isFalse);
      expect(await fakeStorage.loadSession(), isNull);
    });
  });

  group('Provider Riverpod Integration Tests', () {
    test('userGenderProvider and userAvatarAssetProvider reflect restored user', () async {
      final container = ProviderContainer(
        overrides: [
          authSessionStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      await fakeStorage.saveSession(token: sampleUser.token!, user: sampleUser);

      // Restore session
      await container.read(authNotifierProvider.notifier).restoreSession();

      expect(container.read(authTokenProvider), 'saved-token-123');
      expect(container.read(userGenderProvider), 'boy');
      expect(container.read(userAvatarAssetProvider), 'assets/images/dashboard/avatar_boy.png');
      expect(container.read(userDisplayNameProvider), 'Sanctuary Reader');
    });

    test('userDisplayNameProvider falls back to capitalized email prefix if displayName is Reader or empty', () async {
      const emailUser = AuthUser(
        id: 'user-789',
        email: 'arush@sanctuary.app',
        token: 'token-789',
        displayName: 'Reader',
        gender: 'boy',
      );
      final container = ProviderContainer(
        overrides: [
          authSessionStorageProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      await fakeStorage.saveSession(token: emailUser.token!, user: emailUser);
      await container.read(authNotifierProvider.notifier).restoreSession();

      expect(container.read(userDisplayNameProvider), 'Arush');
    });

    test('userDisplayNameProvider updates when profile display name is updated', () async {
      final container = ProviderContainer(
        overrides: [
          authSessionStorageProvider.overrideWithValue(fakeStorage),
          authApiServiceProvider.overrideWithValue(fakeApiService),
        ],
      );
      addTearDown(container.dispose);

      await fakeStorage.saveSession(token: sampleUser.token!, user: sampleUser);
      await container.read(authNotifierProvider.notifier).restoreSession();

      await container.read(authNotifierProvider.notifier).updateDisplayName('Arush Paturi');

      expect(container.read(userDisplayNameProvider), 'Arush Paturi');
    });

    test('userDisplayNameProvider returns Reader when unauthenticated or logged out', () async {
      final container = ProviderContainer(
        overrides: [
          authSessionStorageProvider.overrideWithValue(fakeStorage),
          authApiServiceProvider.overrideWithValue(fakeApiService),
        ],
      );
      addTearDown(container.dispose);

      // Initially unauthenticated
      expect(container.read(userDisplayNameProvider), 'Reader');

      // Login
      fakeApiService.loginResult = sampleUser;
      fakeApiService.userProfileResult = sampleUser;
      await container.read(authNotifierProvider.notifier).login(
        email: 'test@sanctuary.app',
        password: 'password123',
      );
      expect(container.read(userDisplayNameProvider), 'Sanctuary Reader');

      // Logout clears name completely
      await container.read(authNotifierProvider.notifier).logout();
      expect(container.read(userDisplayNameProvider), 'Reader');
    });

    test('Account scenarios: registration, switching accounts, and restarting app', () async {
      final container = ProviderContainer(
        overrides: [
          authSessionStorageProvider.overrideWithValue(fakeStorage),
          authApiServiceProvider.overrideWithValue(fakeApiService),
        ],
      );
      addTearDown(container.dispose);

      // 1. Signup with username Anisha
      const anishaUser = AuthUser(
        id: 'user-anisha',
        email: 'anisha@sanctuary.app',
        token: 'token-anisha',
        displayName: 'Anisha',
      );
      fakeApiService.registerResult = anishaUser;
      fakeApiService.userProfileResult = anishaUser;
      await container.read(authNotifierProvider.notifier).register(
        email: 'anisha@sanctuary.app',
        password: 'password',
        username: 'Anisha',
      );
      expect(container.read(userDisplayNameProvider), 'Anisha');

      // 2. Logout -> Displays no previous account name ('Reader')
      await container.read(authNotifierProvider.notifier).logout();
      expect(container.read(userDisplayNameProvider), 'Reader');

      // 3. Login with another account (e.g. Bob)
      const bobUser = AuthUser(
        id: 'user-bob',
        email: 'bob@sanctuary.app',
        token: 'token-bob',
        displayName: 'Bob',
      );
      fakeApiService.loginResult = bobUser;
      fakeApiService.userProfileResult = bobUser;
      await container.read(authNotifierProvider.notifier).login(
        email: 'bob@sanctuary.app',
        password: 'password',
      );
      expect(container.read(userDisplayNameProvider), 'Bob');

      // 4. Restart application (restore session) -> Restores correct account name
      final restartContainer = ProviderContainer(
        overrides: [
          authSessionStorageProvider.overrideWithValue(fakeStorage),
          authApiServiceProvider.overrideWithValue(fakeApiService),
        ],
      );
      addTearDown(restartContainer.dispose);

      await restartContainer.read(authNotifierProvider.notifier).restoreSession();
      expect(restartContainer.read(userDisplayNameProvider), 'Bob');
    });
  });
}

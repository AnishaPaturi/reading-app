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
    });
  });
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:reading_sanctuary_app/app/router.dart';
import 'package:reading_sanctuary_app/core/network/api_client.dart';
import 'package:reading_sanctuary_app/core/network/api_exception.dart';
import 'package:reading_sanctuary_app/features/authentication/data/models/auth_user.dart';
import 'package:reading_sanctuary_app/features/authentication/data/services/auth_api_service.dart';
import 'package:reading_sanctuary_app/features/authentication/data/services/session_storage.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/providers/auth_provider.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:reading_sanctuary_app/features/reader/data/models/reader_annotations.dart';
import 'package:reading_sanctuary_app/features/reader/data/models/reader_position.dart';
import 'package:reading_sanctuary_app/features/reader/data/repositories/reader_repository.dart';
import 'package:reading_sanctuary_app/features/reader/data/services/reader_file_service.dart';
import 'package:reading_sanctuary_app/features/reader/presentation/providers/reader_provider.dart';
import 'package:reading_sanctuary_app/features/reader/presentation/widgets/reader_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DelayedSessionStorage implements AuthSessionStorage {
  final Completer<AuthSessionData?> _completer;
  int loadCalls = 0;
  int clearCalls = 0;
  int saveCalls = 0;

  _DelayedSessionStorage(this._completer);

  @override
  Future<AuthSessionData?> loadSession() {
    loadCalls++;
    return _completer.future;
  }

  @override
  Future<void> saveSession({required String token, required AuthUser user}) async {
    saveCalls++;
  }

  @override
  Future<void> clearSession() async {
    clearCalls++;
  }
}

class _FakeAuthApiService extends AuthApiService {
  bool throwUnauthorizedOnProfile;
  int fetchProfileCalls = 0;

  _FakeAuthApiService({this.throwUnauthorizedOnProfile = false})
      : super(apiClient: ApiClient(baseUrl: 'http://localhost', tokenProvider: () => null));

  @override
  Future<AuthUser> fetchUserProfile() async {
    fetchProfileCalls++;
    if (throwUnauthorizedOnProfile) {
      throw const UnauthorizedException('Session expired');
    }
    return const AuthUser(
      id: 'user-1',
      email: 'reader@example.com',
      displayName: 'Sanctuary Reader',
    );
  }
}

class _FakeReaderFileService extends ReaderFileService {
  final String? Function() readToken;
  String? lastSeenToken;

  _FakeReaderFileService(this.readToken) : super(tokenProvider: readToken);

  @override
  Future<Uint8List> loadFileBytes({
    required String bookId,
    required String fileId,
  }) async {
    lastSeenToken = readToken();
    if (lastSeenToken == null || lastSeenToken!.isEmpty) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    return Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]);
  }
}

class _FakeReaderRepository implements ReaderRepository {
  final ReaderPosition? position;

  _FakeReaderRepository({this.position});

  @override
  Future<ReaderPosition?> getPosition({required String bookId, required String fileId}) async =>
      position;

  @override
  Future<void> saveLocalPosition({
    required String bookId,
    required String fileId,
    required ReaderPosition position,
  }) async {}

  @override
  Future<ReaderPosition> savePosition({
    required String bookId,
    required String fileId,
    required ReaderPosition position,
  }) async =>
      position;

  @override
  Future<void> resetPosition({required String bookId, required String fileId}) async {}

  @override
  Future<List<ReaderBookmark>> getBookmarks({required String bookId}) async => const [];

  @override
  Future<ReaderBookmark> createBookmark({
    required String bookId,
    required String bookFileId,
    required String locationType,
    required String locationValue,
    int? pageNumber,
    String? label,
    String? note,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteBookmark({required String bookId, required String bookmarkId}) async {}

  @override
  Future<List<ReaderHighlight>> getHighlights({required String bookId}) async => const [];

  @override
  Future<ReaderHighlight> createHighlight({
    required String bookId,
    required String bookFileId,
    required String selectedText,
    required String locationType,
    required String startLocation,
    required String endLocation,
    int? pageNumber,
    ReaderHighlightColor color = ReaderHighlightColor.yellow,
    String? annotationNote,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteHighlight({required String bookId, required String highlightId}) async {}

  @override
  Future<List<ReaderBookNote>> getNotes({required String bookId}) async => const [];

  @override
  Future<ReaderBookNote> createNote({
    required String bookId,
    required String title,
    required String content,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> deleteNote({required String bookId, required String noteId}) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('restoreSession deduplicates concurrent calls and marks restored state', () async {
    final completer = Completer<AuthSessionData?>();
    final storage = _DelayedSessionStorage(completer);
    final api = _FakeAuthApiService();

    final container = ProviderContainer(
      overrides: [
        authSessionStorageProvider.overrideWithValue(storage),
        authApiServiceProvider.overrideWithValue(api),
        googleSignInProvider.overrideWithValue(GoogleSignIn(clientId: 'test-client')),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authNotifierProvider.notifier);
    final f1 = notifier.restoreSession();
    final f2 = notifier.restoreSession();

    expect(container.read(authSessionRestoredProvider), isFalse);

    completer.complete(
      const AuthSessionData(
        token: 'jwt-token-123',
        user: AuthUser(
          id: 'user-1',
          email: 'reader@example.com',
          token: 'jwt-token-123',
          displayName: 'Sanctuary Reader',
        ),
      ),
    );

    final results = await Future.wait([f1, f2]);
    expect(results, [true, true]);
    expect(storage.loadCalls, 1);
    expect(api.fetchProfileCalls, 1);
    expect(container.read(authSessionRestoredProvider), isTrue);
    expect(container.read(authSessionExpiredProvider), isFalse);
    expect(container.read(authTokenProvider), 'jwt-token-123');
    expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
  });

  test('expired stored token triggers authSessionExpiredProvider and clears session', () async {
    final completer = Completer<AuthSessionData?>();
    final storage = _DelayedSessionStorage(completer);
    final api = _FakeAuthApiService(throwUnauthorizedOnProfile: true);

    final container = ProviderContainer(
      overrides: [
        authSessionStorageProvider.overrideWithValue(storage),
        authApiServiceProvider.overrideWithValue(api),
        googleSignInProvider.overrideWithValue(GoogleSignIn(clientId: 'test-client')),
      ],
    );
    addTearDown(container.dispose);

    completer.complete(
      const AuthSessionData(
        token: 'expired-jwt',
        user: AuthUser(
          id: 'user-1',
          email: 'reader@example.com',
          token: 'expired-jwt',
        ),
      ),
    );

    final restored = await container.read(authNotifierProvider.notifier).restoreSession();
    expect(restored, isFalse);

    expect(container.read(authSessionRestoredProvider), isTrue);
    expect(container.read(authSessionExpiredProvider), isTrue);
    expect(container.read(authTokenProvider), isNull);
    expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
    expect(storage.clearCalls, 1);
  });

  testWidgets('reader route preserves URL while restoring and redirects with expired flag when invalid',
      (tester) async {
    final completer = Completer<AuthSessionData?>();
    final storage = _DelayedSessionStorage(completer);
    final api = _FakeAuthApiService(throwUnauthorizedOnProfile: true);

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStorageProvider.overrideWithValue(storage),
          authApiServiceProvider.overrideWithValue(api),
          googleSignInProvider.overrideWithValue(GoogleSignIn(clientId: 'test-client')),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final router = ref.watch(routerProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    final router = container.read(routerProvider);
    router.go('/reader/book-1/file-1?title=Dune&format=EPUB');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // While restoration is in flight, reader route stays active showing loading view
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/reader/book-1/file-1?title=Dune&format=EPUB',
    );
    expect(find.byType(ReaderLoadingView), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    // Complete restoration with expired token
    completer.complete(
      const AuthSessionData(
        token: 'expired-jwt',
        user: AuthUser(
          id: 'user-1',
          email: 'reader@example.com',
          token: 'expired-jwt',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    final loginUri = router.routerDelegate.currentConfiguration.uri;
    expect(loginUri.path, '/login');
    expect(loginUri.queryParameters['redirect'], '/reader/book-1/file-1?title=Dune&format=EPUB');
    expect(loginUri.queryParameters['expired'], '1');
    expect(storage.loadCalls, 1);
    expect(api.fetchProfileCalls, 1);
  });

  testWidgets('reader route redirects to login without expired flag when no session exists',
      (tester) async {
    final completer = Completer<AuthSessionData?>();
    final storage = _DelayedSessionStorage(completer);
    final api = _FakeAuthApiService();

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStorageProvider.overrideWithValue(storage),
          authApiServiceProvider.overrideWithValue(api),
          googleSignInProvider.overrideWithValue(GoogleSignIn(clientId: 'test-client')),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final router = ref.watch(routerProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    final router = container.read(routerProvider);
    router.go('/reader/book-1/file-1?title=Dune&format=EPUB');
    await tester.pump();

    completer.complete(null);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    final loginUri = router.routerDelegate.currentConfiguration.uri;
    expect(loginUri.path, '/login');
    expect(loginUri.queryParameters['redirect'], '/reader/book-1/file-1?title=Dune&format=EPUB');
    expect(loginUri.queryParameters.containsKey('expired'), isFalse);
    expect(api.fetchProfileCalls, 0);
  });

  testWidgets('valid restored session keeps reader URL, mounts ReaderScreen, and restores EPUB CFI position',
      (tester) async {
    final completer = Completer<AuthSessionData?>();
    final storage = _DelayedSessionStorage(completer);
    final api = _FakeAuthApiService();
    const savedPosition = ReaderPosition(
      locationType: 'EPUB_CFI',
      locationValue: 'epubcfi(/6/8[chap04]!/4/2/12)',
      progressPercentage: 42.5,
    );
    late _FakeReaderFileService fakeFileService;
    final fakeRepo = _FakeReaderRepository(position: savedPosition);

    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStorageProvider.overrideWithValue(storage),
          authApiServiceProvider.overrideWithValue(api),
          googleSignInProvider.overrideWithValue(GoogleSignIn(clientId: 'test-client')),
          readerRepositoryProvider.overrideWithValue(fakeRepo),
          readerFileServiceProvider.overrideWith((ref) {
            final token = ref.watch(authTokenProvider);
            fakeFileService = _FakeReaderFileService(() => token);
            return fakeFileService;
          }),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            final router = ref.watch(routerProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    final router = container.read(routerProvider);
    // Use DOCX for headless widget mount (EPUB WebView requires native platform implementation).
    router.go('/reader/book-1/file-1?title=Dune&format=DOCX');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ReaderLoadingView), findsOneWidget);

    completer.complete(
      const AuthSessionData(
        token: 'valid-jwt-token',
        user: AuthUser(
          id: 'user-1',
          email: 'reader@example.com',
          token: 'valid-jwt-token',
          displayName: 'Sanctuary Reader',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Session is restored, URL & query parameters are preserved, and ReaderScreen mounts.
    expect(container.read(authSessionRestoredProvider), isTrue);
    expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/reader/book-1/file-1?title=Dune&format=DOCX',
    );
    expect(find.byType(LoginScreen), findsNothing);
    expect(storage.loadCalls, 1);
    expect(api.fetchProfileCalls, 1);

    // Verify EPUB file loading & saved EPUB_CFI reading position restoration with restored token.
    final epubDoc = await container.read(
      readerDocumentProvider(
        const ReaderDocumentArgs(
          bookId: 'book-1',
          fileId: 'file-1',
          bookTitle: 'Dune',
          fileFormat: 'EPUB',
        ),
      ).future,
    );
    expect(fakeFileService.lastSeenToken, 'valid-jwt-token');
    expect(epubDoc.initialPosition?.locationType, 'EPUB_CFI');
    expect(epubDoc.initialPosition?.locationValue, 'epubcfi(/6/8[chap04]!/4/2/12)');
    expect(epubDoc.initialPosition?.progressPercentage, 42.5);
  });
}

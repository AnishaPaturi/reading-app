import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reading_sanctuary_app/features/authentication/data/models/auth_user.dart';
import 'package:reading_sanctuary_app/features/authentication/data/services/session_storage.dart';
import 'package:reading_sanctuary_app/features/splash/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mockUser = AuthUser(
    id: 'user-777',
    email: 'autologin@sanctuary.app',
    token: 'jwt-persisted-auto-token',
    displayName: 'Mia Reader',
  );

  Widget buildRouterApp({
    required InMemoryAuthSessionStorage storage,
    required List<String> navigatedRoutes,
  }) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) {
            navigatedRoutes.add('/home');
            return const Scaffold(body: Text('Home Screen Content'));
          },
        ),
        GoRoute(
          path: '/landing',
          builder: (context, state) {
            navigatedRoutes.add('/landing');
            return const Scaffold(body: Text('Landing Screen Content'));
          },
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authSessionStorageProvider.overrideWithValue(storage),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('SplashScreen navigates to /home when user has an existing session', (tester) async {
    final storage = InMemoryAuthSessionStorage();
    await storage.saveSession(token: mockUser.token!, user: mockUser);
    final routes = <String>[];

    await tester.pumpWidget(buildRouterApp(storage: storage, navigatedRoutes: routes));
    expect(find.text('Reading Sanctuary'), findsOneWidget);

    // Advance past the 1600ms splash delay and settle animations
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(routes, contains('/home'));
    expect(find.text('Home Screen Content'), findsOneWidget);
  });

  testWidgets('SplashScreen navigates to /landing when user has no stored session', (tester) async {
    final storage = InMemoryAuthSessionStorage();
    final routes = <String>[];

    await tester.pumpWidget(buildRouterApp(storage: storage, navigatedRoutes: routes));
    expect(find.text('Reading Sanctuary'), findsOneWidget);

    // Advance past the 1600ms splash delay and settle animations
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(routes, contains('/landing'));
    expect(find.text('Landing Screen Content'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reading_sanctuary_app/features/landing/presentation/screens/landing_screen.dart';

Widget _buildLandingTestApp({List<String>? navigatedRoutes}) {
  final router = GoRouter(
    initialLocation: '/landing',
    routes: [
      GoRoute(
        path: '/landing',
        builder: (_, __) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) {
          navigatedRoutes?.add('/login');
          return const Scaffold(body: Text('Login Screen Mock'));
        },
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LandingScreen Tests', () {
    testWidgets('renders landing slide and Let\'s go button navigates to login', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Verify Skip button exists
      expect(find.text('Skip'), findsOneWidget);

      // Verify Let's go button exists
      expect(find.byTooltip("Let's go"), findsOneWidget);

      // Verify removed notification slide elements are NOT present
      expect(find.byTooltip('Turn on notifications'), findsNothing);
      expect(find.text("Don't miss what your friends are reading."), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);

      // Tap Let's go
      await tester.tap(find.byTooltip("Let's go"));
      await tester.pumpAndSettle();

      // Should now be on login screen
      expect(routes, contains('/login'));
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });

    testWidgets('Skip button navigates to login', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(routes, contains('/login'));
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });
  });
}

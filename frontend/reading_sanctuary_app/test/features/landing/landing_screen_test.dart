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
    testWidgets('renders first slide and advances on Let\'s Go tap', (tester) async {
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

      // Tap Let's go
      await tester.tap(find.byTooltip("Let's go"));
      await tester.pumpAndSettle();

      // Should now be on slide 2
      expect(find.byTooltip('Turn on notifications'), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget);
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

    testWidgets('Back button returns to slide 1 from slide 2', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildLandingTestApp());
      await tester.pumpAndSettle();

      // Move to slide 2
      await tester.tap(find.byTooltip("Let's go"));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back'), findsOneWidget);

      // Tap Back
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      // Back on slide 1
      expect(find.byTooltip("Let's go"), findsOneWidget);
    });

    testWidgets('Tapping Turn on notifications triggers feedback and navigates', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Move to slide 2
      await tester.tap(find.byTooltip("Let's go"));
      await tester.pumpAndSettle();

      // Tap Turn on notifications
      await tester.tap(find.byTooltip('Turn on notifications'));
      await tester.pump();
      expect(find.text('Notifications enabled!'), findsOneWidget);

      // Advance timer for delayed navigation
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(routes, contains('/login'));
    });
  });
}

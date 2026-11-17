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
    testWidgets(
        'renders existing landing slide and verifies Skip is completely removed',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Verify Skip button does NOT exist
      expect(find.text('Skip'), findsNothing);

      // Verify Page 1 Get Started / Let's go button exists
      expect(
          find.byKey(const Key('first_landing_get_started')), findsOneWidget);
      expect(find.byTooltip("Let's go"), findsOneWidget);

      // Verify removed notification slide elements are NOT present
      expect(find.byTooltip('Turn on notifications'), findsNothing);
      expect(
          find.text("Don't miss what your friends are reading."), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets(
        'first landing page Get Started button transitions to second landing page',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Tap first page's Get Started button
      await tester.tap(find.byKey(const Key('first_landing_get_started')));
      await tester.pumpAndSettle();

      // Verify we transitioned to page 2 (Why Choose Us?)
      expect(find.text('Why Choose Us?'), findsOneWidget);
      expect(find.text("We're Here For You 💜"), findsOneWidget);
      expect(find.text('Reading Dashboard'), findsOneWidget);
      expect(find.text('3D Custom Bookshelves'), findsOneWidget);
      expect(find.text('Smart Library'), findsOneWidget);
      expect(find.text('Reading Stats & Goals'), findsOneWidget);

      // Verify login wasn't triggered yet
      expect(routes, isEmpty);
    });

    testWidgets('can swipe horizontally between landing pages', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Initially on Page 1
      expect(
          find.byKey(const Key('first_landing_get_started')), findsOneWidget);
      expect(find.text('Why Choose Us?'), findsNothing);

      // Swipe left to go to Page 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Why Choose Us?'), findsOneWidget);

      // Swipe right to return to Page 1
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('first_landing_get_started')), findsOneWidget);
    });

    testWidgets('second landing page Get Started button navigates to /login',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Go to page 2
      await tester.tap(find.byKey(const Key('first_landing_get_started')));
      await tester.pumpAndSettle();

      // Tap second landing Get Started
      await tester
          .ensureVisible(find.byKey(const Key('second_landing_get_started')));
      await tester.tap(find.byKey(const Key('second_landing_get_started')));
      await tester.pumpAndSettle();

      expect(routes, contains('/login'));
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });

    testWidgets('second landing page Login button navigates to /login',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Go to page 2
      await tester.tap(find.byKey(const Key('first_landing_get_started')));
      await tester.pumpAndSettle();

      // Tap second landing Login
      await tester.ensureVisible(find.byKey(const Key('second_landing_login')));
      await tester.tap(find.byKey(const Key('second_landing_login')));
      await tester.pumpAndSettle();

      expect(routes, contains('/login'));
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });

    testWidgets(
        "Let's go button hitbox is aligned with visible button artwork at bottom of slide",
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      final buttonFinder = find.byTooltip("Let's go");
      expect(buttonFinder, findsOneWidget);

      final buttonRect = tester.getRect(buttonFinder);
      final slideFinder = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/images/landing/landing_slide_1.png',
      );
      expect(slideFinder, findsOneWidget);
      final slideRect = tester.getRect(slideFinder);

      // Verify hitbox is aligned near the bottom of the slide artwork (between 2% and 10% from bottom)
      final bottomOffset = slideRect.bottom - buttonRect.bottom;
      final bottomRatio = bottomOffset / slideRect.height;
      expect(bottomRatio, closeTo(0.02, 0.015));

      // Tapping at 5% from the bottom of the slide (where the visible button artwork is located)
      final visibleButtonPoint = Offset(
        slideRect.center.dx,
        slideRect.bottom - (slideRect.height * 0.05),
      );
      await tester.tapAt(visibleButtonPoint);
      await tester.pumpAndSettle();

      // Now moves to Page 2
      expect(find.text('Why Choose Us?'), findsOneWidget);
    });
  });
}

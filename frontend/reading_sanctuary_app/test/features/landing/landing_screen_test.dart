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
        'renders first landing slide and verifies Skip is completely removed',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Verify Skip button does NOT exist
      expect(find.text('Skip'), findsNothing);

      // Verify Slide 1 Get Started / Let's go button exists
      expect(
          find.byKey(const Key('first_landing_get_started')), findsOneWidget);
      expect(find.byTooltip("Let's go"), findsOneWidget);

      // Verify removed notification elements are NOT present
      expect(find.byTooltip('Turn on notifications'), findsNothing);
      expect(
          find.text("Don't miss what your friends are reading."), findsNothing);
      expect(find.byTooltip('Back'), findsNothing);
    });

    testWidgets(
        'first landing slide button transitions to second landing slide',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Tap first page's button
      await tester.tap(find.byKey(const Key('first_landing_get_started')));
      await tester.pumpAndSettle();

      // Verify Slide 2 is now visible
      final slide2Finder = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/images/landing/landing_slide_2.png',
      );
      expect(slide2Finder, findsOneWidget);

      // Verify Slide 2 Get Started button exists
      expect(
          find.byKey(const Key('second_landing_get_started')), findsOneWidget);

      // Verify login was not triggered yet
      expect(routes, isEmpty);
    });

    testWidgets('can swipe horizontally between landing slides',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Initially on Slide 1
      expect(
          find.byKey(const Key('first_landing_get_started')), findsOneWidget);

      // Swipe left to go to Slide 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('second_landing_get_started')), findsOneWidget);

      // Swipe right to return to Slide 1
      await tester.drag(find.byType(PageView), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(
          find.byKey(const Key('first_landing_get_started')), findsOneWidget);
    });

    testWidgets('second landing slide Get Started button navigates to /login',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Go to slide 2
      await tester.tap(find.byKey(const Key('first_landing_get_started')));
      await tester.pumpAndSettle();

      // Tap second slide Get Started button
      await tester.tap(find.byKey(const Key('second_landing_get_started')));
      await tester.pumpAndSettle();

      expect(routes, contains('/login'));
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });

    testWidgets(
        "Let's go button hitbox is aligned with visible button artwork at bottom of slide 1",
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

      // Now on Slide 2
      expect(
          find.byKey(const Key('second_landing_get_started')), findsOneWidget);
    });

    testWidgets(
        "Get Started button hitbox is aligned with visible button artwork at bottom of slide 2",
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final routes = <String>[];
      await tester.pumpWidget(_buildLandingTestApp(navigatedRoutes: routes));
      await tester.pumpAndSettle();

      // Move to slide 2
      await tester.tap(find.byKey(const Key('first_landing_get_started')));
      await tester.pumpAndSettle();

      final buttonFinder = find.byKey(const Key('second_landing_get_started'));
      expect(buttonFinder, findsOneWidget);

      final buttonRect = tester.getRect(buttonFinder);
      final slide2Finder = find.byWidgetPredicate(
        (w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName ==
                'assets/images/landing/landing_slide_2.png',
      );
      expect(slide2Finder, findsOneWidget);
      final slide2Rect = tester.getRect(slide2Finder);

      // Verify hitbox is aligned near the bottom of slide 2 artwork
      final bottomOffset = slide2Rect.bottom - buttonRect.bottom;
      final bottomRatio = bottomOffset / slide2Rect.height;
      expect(bottomRatio, closeTo(0.02, 0.015));

      // Tapping at 5% from the bottom of slide 2 navigates to login
      final visibleButtonPoint = Offset(
        slide2Rect.center.dx,
        slide2Rect.bottom - (slide2Rect.height * 0.05),
      );
      await tester.tapAt(visibleButtonPoint);
      await tester.pumpAndSettle();

      expect(routes, contains('/login'));
      expect(find.text('Login Screen Mock'), findsOneWidget);
    });
  });
}

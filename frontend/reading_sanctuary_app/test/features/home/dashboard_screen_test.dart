import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/home/home_screen.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/hero_reading_banner.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_panel_header.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';

void main() {
  Widget buildTestableWidget({Size size = const Size(1200, 900)}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const HomeScreen(),
        ),
      ),
    );
  }

  testWidgets('Renders Currently Reading and Currently Listening sections with progress bars', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(1200, 900)));
    await tester.pumpAndSettle();

    // Verify Sidebar exists with only the 6 items
    expect(find.byType(ReaderSidebar), findsOneWidget);
    expect(find.text('Hello, Reader!'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Favourites'), findsWidgets);
    expect(find.text('Audiobooks'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Verify removed items are not present
    expect(find.text('Booklists'), findsNothing);
    expect(find.text('My Progress'), findsNothing);

    // Verify Header
    expect(find.byType(ReaderPanelHeader), findsOneWidget);
    expect(find.text('Reader Panel'), findsOneWidget);
    expect(find.text('Search books, authors, genres...'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // Notification badge

    // Verify Section Headers
    expect(find.text('Currently Reading'), findsOneWidget);
    expect(find.text('Currently Listening'), findsOneWidget);
    expect(find.text('Pick up where you left off'), findsOneWidget);
    expect(find.text('Audiobooks in progress'), findsOneWidget);

    // Verify Currently Reading Books & Progress Bars
    expect(find.text('The Silent Patient'), findsWidgets);
    expect(find.text('The Seven Husbands of Evelyn Hugo'), findsWidgets);
    expect(find.textContaining('Completed'), findsWidgets);
    expect(find.textContaining('Listened'), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsWidgets);

    // Verify Interactive Action Buttons
    expect(find.textContaining('Continue Reading'), findsWidgets);
    expect(find.textContaining('Listen Now'), findsWidgets);
  });

  testWidgets('Renders mobile layout with drawer toggle', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(400, 850)));
    await tester.pumpAndSettle();

    // Menu hamburger button is present on mobile
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.text('Reader Panel'), findsOneWidget);

    // Verify 3D Bottom Navigation bar on mobile
    expect(find.byType(ClayBottomNav), findsOneWidget);

    // Open drawer
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    // Verify drawer contents
    expect(find.text('Hello, Reader!'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('Renders profile section in header and opens options menu', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(1200, 900)));
    await tester.pumpAndSettle();

    // Verify Profile in Sidebar
    expect(find.text('Profile'), findsWidgets);

    // Tap Profile in Header menu bar
    final profileMenu = find.byTooltip('Profile options');
    expect(profileMenu, findsOneWidget);
    await tester.tap(profileMenu);
    await tester.pumpAndSettle();

    // Verify popup menu items
    expect(find.text('Sign Out'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('Dashboard route (/dashboard) and Home route (/home) render the exact same screen in sync', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Verify HomeScreen / Dashboard is rendered on /dashboard
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Reader Panel'), findsOneWidget);
    expect(find.text('Currently Reading'), findsOneWidget);

    // Navigate to /home
    router.go('/home');
    await tester.pumpAndSettle();

    // Verify exact same screen is rendered on /home
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Reader Panel'), findsOneWidget);
    expect(find.text('Currently Reading'), findsOneWidget);
  });

  testWidgets('HeroReadingBanner renders personalized greeting based on time and username, with Start reading button removed', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Morning test: 9:00 AM
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HeroReadingBanner(
              currentTime: DateTime(2026, 11, 10, 9, 0),
              customUserName: 'Anisha',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good morning, Anisha!'), findsOneWidget);
    expect(find.text("Let's read some books today!"), findsOneWidget);
    expect(find.text('Start Reading'), findsNothing);
    expect(find.text('Start reading'), findsNothing);

    // Afternoon test: 2:00 PM
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HeroReadingBanner(
              currentTime: DateTime(2026, 11, 10, 14, 0),
              customUserName: 'Mia',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good afternoon, Mia!'), findsOneWidget);
    expect(find.text('Start Reading'), findsNothing);

    // Evening test: 8:00 PM
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: HeroReadingBanner(
              currentTime: DateTime(2026, 11, 10, 20, 0),
              customUserName: 'Alex',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Good evening, Alex!'), findsOneWidget);
    expect(find.text('Start Reading'), findsNothing);
  });

  testWidgets('Audiobooks section displays all audiobooks and is scrollable', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(1200, 900)));
    await tester.pumpAndSettle();

    // Verify Audiobook badge shows in-progress audiobooks (2 audiobooks)
    expect(find.text('2 Audiobooks'), findsOneWidget);

    // Verify first audiobook card is visible
    expect(find.text('The Silent Patient'), findsWidgets);

    // Find the ListView in the Audiobooks section and drag to scroll
    final audiobooksListView = find.byWidgetPredicate(
      (w) => w is ListView && w.physics is AlwaysScrollableScrollPhysics,
    );
    expect(audiobooksListView, findsOneWidget);

    // Drag up to scroll through audiobooks
    await tester.drag(audiobooksListView, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Verify subsequent audiobooks scrolled into view
    expect(find.text('The Psychology of Money'), findsWidgets);
  });
}

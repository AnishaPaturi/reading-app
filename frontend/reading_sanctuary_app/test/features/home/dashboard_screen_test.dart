import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/home/home_screen.dart';
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

    // Verify Sidebar exists
    expect(find.byType(ReaderSidebar), findsOneWidget);
    expect(find.text('Hello, Mia!'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My Library'), findsOneWidget);
    expect(find.text('Favorites'), findsWidgets);
    expect(find.text('Booklists'), findsOneWidget);
    expect(find.text('Audiobooks'), findsOneWidget);
    expect(find.text('My Progress'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify Header
    expect(find.byType(ReaderPanelHeader), findsOneWidget);
    expect(find.text('Reader Panel'), findsOneWidget);
    expect(find.text('Search books, authors, genres...'), findsOneWidget);
    expect(find.text('9'), findsOneWidget); // Notification badge

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
    expect(find.text('Hello, Mia!'), findsOneWidget);
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
}

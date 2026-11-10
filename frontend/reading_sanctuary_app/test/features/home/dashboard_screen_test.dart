import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/home/home_screen.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/discover_banner.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/hero_reading_banner.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/metric_cards_row.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_panel_header.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reading_overview_chart.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/recently_read_card.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/todays_picks_card.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/top_genres_chart.dart';

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

  testWidgets('Renders all dashboard widgets on desktop layout', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(1200, 900)));
    await tester.pumpAndSettle();

    // Verify Sidebar exists
    expect(find.byType(ReaderSidebar), findsOneWidget);
    expect(find.text('Hello, Mia!'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
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

    // Verify Hero Banner
    expect(find.byType(HeroReadingBanner), findsOneWidget);

    // Verify Metric Cards
    expect(find.byType(MetricCardsRow), findsOneWidget);
    expect(find.text('Books Read'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('34.6'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);

    // Verify Charts
    expect(find.byType(ReadingOverviewChart), findsOneWidget);
    expect(find.text('Reading Overview'), findsOneWidget);
    expect(find.byType(TopGenresChart), findsOneWidget);
    expect(find.text('Top Genres'), findsOneWidget);
    expect(find.text('Fiction'), findsOneWidget);
    expect(find.text('45%'), findsOneWidget);

    // Verify Recently Read & Today's Picks
    expect(find.byType(RecentlyReadCard), findsOneWidget);
    expect(find.text('Recently Read'), findsOneWidget);
    expect(find.textContaining('Midnight'), findsOneWidget);
    expect(find.textContaining('Atomic'), findsOneWidget);
    expect(find.textContaining('Little'), findsOneWidget);

    expect(find.byType(TodaysPicksCard), findsOneWidget);
    expect(find.text("Today's Picks"), findsOneWidget);
    expect(find.text('Cozy Reads'), findsOneWidget);

    // Verify Bottom Discover Banner
    expect(find.byType(DiscoverBanner), findsOneWidget);
    expect(find.text('Discover new books'), findsOneWidget);
    expect(find.text('Discover Now'), findsOneWidget);
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

    // Open drawer
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    // Verify drawer contents
    expect(find.text('Hello, Mia!'), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
  });
}

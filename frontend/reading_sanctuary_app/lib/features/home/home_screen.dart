import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/widgets/discover_banner.dart';
import 'presentation/widgets/hero_reading_banner.dart';
import 'presentation/widgets/metric_cards_row.dart';
import 'presentation/widgets/reader_panel_header.dart';
import 'presentation/widgets/reader_sidebar.dart';
import 'presentation/widgets/reading_overview_chart.dart';
import 'presentation/widgets/recently_read_card.dart';
import 'presentation/widgets/todays_picks_card.dart';
import 'presentation/widgets/top_genres_chart.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        if (isWide) {
          // Desktop / Tablet layout with pinned sidebar
          return Scaffold(
            backgroundColor: const Color(0xFFF4F0FB),
            body: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left 3D Reader Sidebar
                  const ReaderSidebar(),

                  // Main Reader Panel Content
                  Expanded(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: ReaderPanelHeader(showMenuButton: false),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: _buildDashboardBody(context, contentWidth: constraints.maxWidth - 234),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Mobile layout with drawer
          return Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF4F0FB),
            drawer: Drawer(
              width: 220,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ReaderSidebar(
                width: 220,
                onItemTapped: () => Navigator.of(context).pop(),
              ),
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: ReaderPanelHeader(
                      showMenuButton: true,
                      onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildDashboardBody(context, contentWidth: constraints.maxWidth - 32),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildDashboardBody(BuildContext context, {required double contentWidth}) {
    final useTwoColumns = contentWidth >= 640;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3D Hero Banner: Mia reading, star greeting & Start Reading button
        const HeroReadingBanner(),
        const SizedBox(height: 16),

        // 4 Pastel Metric Cards: Books Read, Favorites, Hours Read, Daily Streak
        const MetricCardsRow(),
        const SizedBox(height: 16),

        // Charts Section: Reading Overview & Top Genres
        if (useTwoColumns)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: ReadingOverviewChart(),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: TopGenresChart(),
              ),
            ],
          )
        else ...[
          const ReadingOverviewChart(),
          const SizedBox(height: 16),
          const TopGenresChart(),
        ],
        const SizedBox(height: 16),

        // Lower Section: Recently Read & Today's Picks
        if (useTwoColumns)
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: RecentlyReadCard(),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: TodaysPicksCard(),
              ),
            ],
          )
        else ...[
          const RecentlyReadCard(),
          const SizedBox(height: 16),
          const TodaysPicksCard(),
        ],
        const SizedBox(height: 16),

        // Bottom Discover New Books Banner with Star Mascot
        const DiscoverBanner(),
        const SizedBox(height: 24),
      ],
    );
  }
}

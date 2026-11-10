import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../application/analytics_providers.dart';
import '../widgets/activity_heatmap.dart';
import '../widgets/analytics_header.dart';
import '../widgets/analytics_overview_cards.dart';
import '../widgets/author_analytics_card.dart';
import '../widgets/genre_pie_chart.dart';
import '../widgets/listening_analytics_card.dart';
import '../widgets/monthly_books_chart.dart';
import '../widgets/reading_activity_chart.dart';
import '../widgets/reading_goals_card.dart';
import '../widgets/reading_pace_card.dart';
import '../widgets/reading_streak_card.dart';

class AnalyticsDashboardScreen extends ConsumerWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(selectedAnalyticsYearProvider);
    final overviewAsync = ref.watch(analyticsOverviewProvider);
    final activityAsync = ref.watch(dailyActivityProvider);
    final streakAsync = ref.watch(readingStreakProvider);
    final paceAsync = ref.watch(readingPaceProvider);
    final booksAsync = ref.watch(booksCompletedProvider);
    final genreAsync = ref.watch(genreAnalyticsProvider);
    final authorAsync = ref.watch(authorAnalyticsProvider);
    final listeningAsync = ref.watch(listeningAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.espresso,
      body: RefreshIndicator(
        color: AppColors.gold,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          ref.invalidate(analyticsOverviewProvider);
          ref.invalidate(dailyActivityProvider);
          ref.invalidate(readingStreakProvider);
          ref.invalidate(readingPaceProvider);
          ref.invalidate(booksCompletedProvider);
          ref.invalidate(genreAnalyticsProvider);
          ref.invalidate(authorAnalyticsProvider);
          ref.invalidate(listeningAnalyticsProvider);
          ref.invalidate(readingGoalsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AnalyticsHeader(),
              const SizedBox(height: 20),

              // Overview Cards
              overviewAsync.when(
                data: (overview) => AnalyticsOverviewCards(overview: overview),
                loading: () => const _LoadingPlaceholder(height: 120),
                error: (e, _) => _ErrorCard(message: 'Overview unavailable: $e'),
              ),
              const SizedBox(height: 20),

              // Reading Streak & Goals
              streakAsync.when(
                data: (streak) => ReadingStreakCard(streak: streak),
                loading: () => const _LoadingPlaceholder(height: 90),
                error: (e, _) => _ErrorCard(message: 'Streak unavailable: $e'),
              ),
              const SizedBox(height: 20),

              const ReadingGoalsCard(),
              const SizedBox(height: 20),

              // Activity Chart
              activityAsync.when(
                data: (activity) => ReadingActivityChart(activity: activity),
                loading: () => const _LoadingPlaceholder(height: 260),
                error: (e, _) => _ErrorCard(message: 'Activity chart unavailable: $e'),
              ),
              const SizedBox(height: 20),

              // Calendar Heatmap
              streakAsync.when(
                data: (streak) => ActivityHeatmap(streak: streak, year: year),
                loading: () => const _LoadingPlaceholder(height: 160),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Monthly Completed Books Chart
              booksAsync.when(
                data: (books) => MonthlyBooksChart(booksCompleted: books),
                loading: () => const _LoadingPlaceholder(height: 220),
                error: (e, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),

              // Reading Pace & Listening Side-by-Side on wide screens
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: paceAsync.when(
                            data: (pace) => ReadingPaceCard(pace: pace),
                            loading: () => const _LoadingPlaceholder(height: 180),
                            error: (e, _) => _ErrorCard(message: 'Pace unavailable: $e'),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: listeningAsync.when(
                            data: (listening) => ListeningAnalyticsCard(listening: listening),
                            loading: () => const _LoadingPlaceholder(height: 180),
                            error: (e, _) => _ErrorCard(message: 'Listening stats unavailable: $e'),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      paceAsync.when(
                        data: (pace) => ReadingPaceCard(pace: pace),
                        loading: () => const _LoadingPlaceholder(height: 180),
                        error: (e, _) => _ErrorCard(message: 'Pace unavailable: $e'),
                      ),
                      const SizedBox(height: 20),
                      listeningAsync.when(
                        data: (listening) => ListeningAnalyticsCard(listening: listening),
                        loading: () => const _LoadingPlaceholder(height: 180),
                        error: (e, _) => _ErrorCard(message: 'Listening stats unavailable: $e'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Genre & Author breakdown
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: genreAsync.when(
                            data: (genres) => GenrePieChart(genreData: genres),
                            loading: () => const _LoadingPlaceholder(height: 220),
                            error: (e, _) => _ErrorCard(message: 'Genres unavailable: $e'),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: authorAsync.when(
                            data: (authors) => AuthorAnalyticsCard(authorData: authors),
                            loading: () => const _LoadingPlaceholder(height: 220),
                            error: (e, _) => _ErrorCard(message: 'Authors unavailable: $e'),
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      genreAsync.when(
                        data: (genres) => GenrePieChart(genreData: genres),
                        loading: () => const _LoadingPlaceholder(height: 220),
                        error: (e, _) => _ErrorCard(message: 'Genres unavailable: $e'),
                      ),
                      const SizedBox(height: 20),
                      authorAsync.when(
                        data: (authors) => AuthorAnalyticsCard(authorData: authors),
                        loading: () => const _LoadingPlaceholder(height: 220),
                        error: (e, _) => _ErrorCard(message: 'Authors unavailable: $e'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingPlaceholder extends StatelessWidget {
  final double height;
  const _LoadingPlaceholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.gold),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.hlRose.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.hlRose, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

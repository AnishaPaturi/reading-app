import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/analytics_overview.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/author_analytics.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/listening_analytics.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/reading_pace.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/reading_streak.dart';
import 'package:reading_sanctuary_app/features/analytics/presentation/widgets/analytics_overview_cards.dart';
import 'package:reading_sanctuary_app/features/analytics/presentation/widgets/author_analytics_card.dart';
import 'package:reading_sanctuary_app/features/analytics/presentation/widgets/listening_analytics_card.dart';
import 'package:reading_sanctuary_app/features/analytics/presentation/widgets/reading_pace_card.dart';
import 'package:reading_sanctuary_app/features/analytics/presentation/widgets/reading_streak_card.dart';

void main() {
  group('Analytics Widgets Test', () {
    testWidgets('renders AnalyticsOverviewCards with metrics', (tester) async {
      const overview = AnalyticsOverviewResponse(
        totalBooks: 42,
        completedBooks: 18,
        currentlyReadingBooks: 3,
        tbrBooks: 19,
        dnfBooks: 2,
        totalReadingMinutes: 1500,
        totalAudiobookMinutes: 420,
        totalTtsMinutes: 180,
        activeReadingDays: 45,
        currentStreakDays: 8,
        booksCompletedThisYear: 12,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnalyticsOverviewCards(overview: overview),
            ),
          ),
        ),
      );

      expect(find.text('Total Books'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('Currently Reading'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('TBR / DNF'), findsOneWidget);
      expect(find.text('19 / 2'), findsOneWidget);
      expect(find.text('Reading Time'), findsOneWidget);
      expect(find.text('25h'), findsOneWidget); // 1500 mins = 25h
      expect(find.text('Listening Time'), findsOneWidget);
      expect(find.text('10h'), findsOneWidget); // 420 + 180 = 600m = 10h
    });

    testWidgets('renders ReadingStreakCard with streak count', (tester) async {
      const streak = StreakResponse(
        currentStreakDays: 14,
        longestStreakDays: 30,
        lastActiveDate: '2026-11-09',
        activeDatesThisYear: ['2026-11-09'],
        totalActiveDaysThisYear: 1,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadingStreakCard(streak: streak),
          ),
        ),
      );

      expect(find.text('14 Day Streak'), findsOneWidget);
      expect(find.text('ON FIRE'), findsOneWidget);
      expect(find.textContaining('Personal best: 30 consecutive reading days'), findsOneWidget);
    });

    testWidgets('renders ReadingPaceCard metrics', (tester) async {
      const pace = ReadingPaceResponse(
        averageMinutesPerDay: 45.0,
        averagePagesPerDay: 35.0,
        averageMinutesPerSession: 22.5,
        totalSessions: 20,
        estimatedCompletionDaysCurrentBook: 5,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReadingPaceCard(pace: pace),
          ),
        ),
      );

      expect(find.text('Daily Pace'), findsOneWidget);
      expect(find.text('45.0m'), findsOneWidget);
      expect(find.text('Page Speed'), findsOneWidget);
      expect(find.text('35.0'), findsOneWidget);
      expect(find.text('Session Avg'), findsOneWidget);
      expect(find.text('22.5m'), findsOneWidget);
      expect(find.textContaining('~5 days to finish current book'), findsOneWidget);
    });

    testWidgets('renders ListeningAnalyticsCard with distinct Audiobook and TTS', (tester) async {
      const listening = ListeningAnalyticsResponse(
        totalListeningMinutes: 300,
        audiobookMinutes: 180,
        ttsMinutes: 120,
        audiobookPercentage: 60.0,
        ttsPercentage: 40.0,
        audiobooksCompleted: 3,
        totalAudiobookSessions: 12,
        totalTtsSessions: 6,
        averageListeningSpeed: 1.25,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ListeningAnalyticsCard(listening: listening),
          ),
        ),
      );

      expect(find.text('Listening Analytics (Audio & TTS)'), findsOneWidget);
      expect(find.text('Audiobooks'), findsOneWidget);
      expect(find.text('Text-to-Speech'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('12 sessions'), findsOneWidget);
      expect(find.text('6 sessions'), findsOneWidget);
      expect(find.text('Avg speed: 1.25x'), findsOneWidget);
    });

    testWidgets('renders AuthorAnalyticsCard ranking list', (tester) async {
      const authors = AuthorAnalyticsResponse(
        totalAuthors: 2,
        topAuthors: [
          AuthorItem(author: 'J.R.R. Tolkien', bookCount: 5, completedCount: 4, readingMinutes: 1200),
          AuthorItem(author: 'Ursula K. Le Guin', bookCount: 3, completedCount: 2, readingMinutes: 700),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthorAnalyticsCard(authorData: authors),
          ),
        ),
      );

      expect(find.text('Top Authors'), findsOneWidget);
      expect(find.text('J.R.R. Tolkien'), findsOneWidget);
      expect(find.text('Ursula K. Le Guin'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('4 / 5 completed'), findsOneWidget);
    });
  });
}

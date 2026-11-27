import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/widgets/clay_bottom_nav_bar.dart';
import 'package:reading_sanctuary_app/features/analytics/application/analytics_providers.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/activity_session.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/analytics_overview.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/author_analytics.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/books_completed.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/daily_activity.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/genre_analytics.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/goal_progress.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/listening_analytics.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/reading_goal.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/reading_pace.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/reading_streak.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/yearly_wrap_up.dart';
import 'package:reading_sanctuary_app/features/analytics/data/repositories/analytics_repository.dart';
import 'package:reading_sanctuary_app/features/calendar/data/models/reading_calendar_models.dart';
import 'package:reading_sanctuary_app/features/calendar/presentation/screens/reading_calendar_screen.dart';

class _FakeAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<CalendarMonthData> getCalendar({int? year, int? month, String? timezone}) async {
    return CalendarMonthData.local(year ?? 2026, month ?? 11);
  }

  @override
  Future<AnalyticsOverviewResponse> getOverview({DateTime? from, DateTime? to, String? timezone}) async {
    throw UnimplementedError();
  }

  @override
  Future<DailyActivityResponse> getActivity({String period = 'MONTH', int? year, int? month, String? timezone}) async {
    throw UnimplementedError();
  }

  @override
  Future<StreakResponse> getStreaks({String? timezone}) async {
    throw UnimplementedError();
  }

  @override
  Future<StreakResponse> toggleStreakFreeze({DateTime? date, String? timezone}) async {
    throw UnimplementedError();
  }

  @override
  Future<StreakResponse> markTodayComplete({String? timezone}) async {
    throw UnimplementedError();
  }

  @override
  Future<ReadingPaceResponse> getReadingPace({int? year, DateTime? from, DateTime? to}) async {
    throw UnimplementedError();
  }

  @override
  Future<BooksCompletedResponse> getBooksCompleted({int? year}) async {
    throw UnimplementedError();
  }

  @override
  Future<GenreAnalyticsResponse> getGenres({int? year}) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthorAnalyticsResponse> getAuthors({int? year}) async {
    throw UnimplementedError();
  }

  @override
  Future<ListeningAnalyticsResponse> getListening({int? year}) async {
    throw UnimplementedError();
  }

  @override
  Future<YearlyWrapUpResponse> getYearlyWrapUp({int? year}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ReadingGoalResponse>> getGoals({bool? activeOnly}) async {
    throw UnimplementedError();
  }

  @override
  Future<ReadingGoalResponse> createGoal(ReadingGoalRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<ReadingGoalResponse> updateGoal(String goalId, ReadingGoalRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    throw UnimplementedError();
  }

  @override
  Future<GoalProgressResponse> getGoalProgress(String goalId) async {
    throw UnimplementedError();
  }

  @override
  Future<ActivitySessionResponse> startSession(ActivitySessionRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<ActivitySessionResponse> sendHeartbeat(String sessionId, ActivityHeartbeatRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<ActivitySessionResponse> closeSession(String sessionId, CloseSessionRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ActivitySessionResponse>> getSessionHistory({int page = 0, int size = 20}) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('ReadingCalendarScreen renders matching mockup layout and elements', (tester) async {
    tester.view.physicalSize = const Size(400, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsRepositoryProvider.overrideWithValue(_FakeAnalyticsRepository()),
        ],
        child: const MaterialApp(
          home: ReadingCalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify title
    expect(find.text('Reading Calendar'), findsOneWidget);

    // 2. Verify Monthly Calendar Grid card & header
    expect(find.text('Monthly Calendar Grid'), findsOneWidget);

    // 3. Verify weekday row (M, T, W, T, F, S, S)
    expect(find.text('M'), findsOneWidget);
    expect(find.text('W'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);

    // 4. Verify special day elements
    // Star tile (top reading day)
    expect(find.text('⭐'), findsWidgets);

    // Select mockup Day 24 so Day Stats are deterministic regardless of current date
    final day24 = find.text('24').first;
    await tester.ensureVisible(day24);
    await tester.tap(day24);
    await tester.pumpAndSettle();

    // 5. Verify Day Stats card
    expect(find.text('Day Stats'), findsOneWidget);
    expect(find.text('Pages Read'), findsOneWidget);
    expect(find.text('Min Listened'), findsOneWidget);
    expect(find.text('Books Active'), findsOneWidget);
    expect(find.text('45'), findsWidgets);
    expect(find.text('52'), findsWidgets);
    expect(find.text('2'), findsWidgets);

    // 6. Verify Monthly Summary card
    expect(find.text('Monthly Summary'), findsOneWidget);
    expect(find.textContaining('Days Read'), findsWidgets);
    expect(find.textContaining('Current Streak:'), findsOneWidget);
    expect(find.textContaining('Freeze Used:'), findsOneWidget);

    // 7. Verify dynamic bottom nav exists with 4 items
    expect(find.byType(ClayBottomNavBar), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_rounded), findsOneWidget);
  });

  testWidgets('ReadingCalendarScreen allows selecting days and navigating months dynamically', (tester) async {
    tester.view.physicalSize = const Size(400, 950);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsRepositoryProvider.overrideWithValue(_FakeAnalyticsRepository()),
        ],
        child: const MaterialApp(
          home: ReadingCalendarScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap day 2 in grid
    final day2 = find.text('2').first;
    await tester.tap(day2);
    await tester.pumpAndSettle();

    // Verify Day Stats updated dynamically to November 2 Details
    expect(find.textContaining('2 Details'), findsOneWidget);

    // Tap next month button (>)
    final nextBtn = find.byTooltip('Next Month');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Verify Month Selector updated dynamically to December 2026
    expect(find.textContaining('December 2026'), findsOneWidget);

    // Tap previous month button (<)
    final prevBtn = find.byTooltip('Previous Month');
    await tester.tap(prevBtn);
    await tester.pumpAndSettle();

    // Verify back to November 2026
    expect(find.textContaining('November 2026'), findsOneWidget);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../reader/presentation/providers/reader_provider.dart';
import '../data/models/analytics_overview.dart';
import '../data/models/author_analytics.dart';
import '../data/models/books_completed.dart';
import '../data/models/daily_activity.dart';
import '../data/models/genre_analytics.dart';
import '../data/models/goal_progress.dart';
import '../data/models/listening_analytics.dart';
import '../data/models/reading_goal.dart';
import '../data/models/reading_pace.dart';
import '../data/models/reading_streak.dart';
import '../data/models/yearly_wrap_up.dart';
import '../data/repositories/analytics_repository.dart';
import '../data/services/activity_tracking_service.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return HttpAnalyticsRepository(
    tokenProvider: () => ref.watch(authTokenProvider),
  );
});

final activityTrackingServiceProvider = Provider<ActivityTrackingService>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  final service = ActivityTrackingService(repo);
  ref.onDispose(() => service.dispose());
  return service;
});

final selectedAnalyticsYearProvider = StateProvider<int>((ref) => DateTime.now().year);

final activityPeriodProvider = StateProvider<String>((ref) => 'MONTH');

final analyticsOverviewProvider = FutureProvider<AnalyticsOverviewResponse>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getOverview();
});

final dailyActivityProvider = FutureProvider<DailyActivityResponse>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final period = ref.watch(activityPeriodProvider);
  final year = ref.watch(selectedAnalyticsYearProvider);
  return repo.getActivity(period: period, year: year);
});

final readingStreakProvider = FutureProvider<StreakResponse>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getStreaks();
});

final readingPaceProvider = FutureProvider<ReadingPaceResponse>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final year = ref.watch(selectedAnalyticsYearProvider);
  return repo.getReadingPace(year: year);
});

final booksCompletedProvider = FutureProvider<BooksCompletedResponse>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final year = ref.watch(selectedAnalyticsYearProvider);
  return repo.getBooksCompleted(year: year);
});

final genreAnalyticsProvider = FutureProvider<GenreAnalyticsResponse>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final year = ref.watch(selectedAnalyticsYearProvider);
  return repo.getGenres(year: year);
});

final authorAnalyticsProvider = FutureProvider<AuthorAnalyticsResponse>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final year = ref.watch(selectedAnalyticsYearProvider);
  return repo.getAuthors(year: year);
});

final listeningAnalyticsProvider = FutureProvider<ListeningAnalyticsResponse>((ref) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  final year = ref.watch(selectedAnalyticsYearProvider);
  return repo.getListening(year: year);
});

final yearlyWrapUpProvider = FutureProvider.family<YearlyWrapUpResponse, int>((ref, year) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getYearlyWrapUp(year: year);
});

class ReadingGoalsNotifier extends AsyncNotifier<List<ReadingGoalResponse>> {
  @override
  Future<List<ReadingGoalResponse>> build() async {
    final repo = ref.read(analyticsRepositoryProvider);
    return repo.getGoals();
  }

  Future<void> createGoal(ReadingGoalRequest request) async {
    final repo = ref.read(analyticsRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.createGoal(request);
      state = AsyncData(await repo.getGoals());
      ref.invalidate(analyticsOverviewProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateGoal(String goalId, ReadingGoalRequest request) async {
    final repo = ref.read(analyticsRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.updateGoal(goalId, request);
      state = AsyncData(await repo.getGoals());
      ref.invalidate(analyticsOverviewProvider);
      ref.invalidate(goalProgressProvider(goalId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteGoal(String goalId) async {
    final repo = ref.read(analyticsRepositoryProvider);
    state = const AsyncLoading();
    try {
      await repo.deleteGoal(goalId);
      state = AsyncData(await repo.getGoals());
      ref.invalidate(analyticsOverviewProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final readingGoalsProvider = AsyncNotifierProvider<ReadingGoalsNotifier, List<ReadingGoalResponse>>(
  ReadingGoalsNotifier.new,
);

final goalProgressProvider = FutureProvider.family<GoalProgressResponse, String>((ref, goalId) async {
  final repo = ref.watch(analyticsRepositoryProvider);
  return repo.getGoalProgress(goalId);
});

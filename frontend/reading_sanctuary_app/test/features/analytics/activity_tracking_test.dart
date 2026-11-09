import 'package:flutter_test/flutter_test.dart';
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
import 'package:reading_sanctuary_app/features/analytics/data/services/activity_tracking_service.dart';

class FakeAnalyticsRepository implements AnalyticsRepository {
  ActivitySessionRequest? lastStartRequest;
  ActivityHeartbeatRequest? lastHeartbeatRequest;
  CloseSessionRequest? lastCloseRequest;
  bool sessionStarted = false;
  bool sessionClosed = false;

  @override
  Future<ActivitySessionResponse> startSession(ActivitySessionRequest request) async {
    lastStartRequest = request;
    sessionStarted = true;
    return ActivitySessionResponse(
      id: 'session-xyz',
      activityType: request.activityType,
      bookId: request.bookId,
      startTime: DateTime.now(),
      durationSeconds: 0,
      pagesRead: 0,
      active: true,
    );
  }

  @override
  Future<ActivitySessionResponse> sendHeartbeat(String sessionId, ActivityHeartbeatRequest request) async {
    lastHeartbeatRequest = request;
    return ActivitySessionResponse(
      id: sessionId,
      activityType: ActivityType.READING,
      startTime: DateTime.now().subtract(const Duration(minutes: 5)),
      durationSeconds: 300,
      pagesRead: request.pagesReadDelta ?? 0,
      active: true,
    );
  }

  @override
  Future<ActivitySessionResponse> closeSession(String sessionId, CloseSessionRequest request) async {
    lastCloseRequest = request;
    sessionClosed = true;
    return ActivitySessionResponse(
      id: sessionId,
      activityType: ActivityType.READING,
      startTime: DateTime.now().subtract(const Duration(minutes: 10)),
      endTime: DateTime.now(),
      durationSeconds: 600,
      pagesRead: request.pagesReadDelta ?? 0,
      active: false,
    );
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
  Future<List<ReadingGoalResponse>> getGoals({bool? activeOnly}) async => [];

  @override
  Future<ReadingGoalResponse> createGoal(ReadingGoalRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<ReadingGoalResponse> updateGoal(String goalId, ReadingGoalRequest request) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteGoal(String goalId) async {}

  @override
  Future<GoalProgressResponse> getGoalProgress(String goalId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<ActivitySessionResponse>> getSessionHistory({int page = 0, int size = 20}) async => [];
}

void main() {
  group('ActivityTrackingService Test', () {
    late FakeAnalyticsRepository fakeRepo;
    late ActivityTrackingService trackingService;

    setUp(() {
      fakeRepo = FakeAnalyticsRepository();
      trackingService = ActivityTrackingService(fakeRepo);
    });

    tearDown(() {
      trackingService.dispose();
    });

    test('starts and closes a reading session', () async {
      expect(trackingService.hasActiveSession, isFalse);

      await trackingService.startSession(
        activityType: ActivityType.READING,
        bookId: 'book-123',
        bookFileId: 'file-456',
        startingLocation: 'page=10',
        startingPage: 10,
      );

      expect(trackingService.hasActiveSession, isTrue);
      expect(trackingService.currentSessionId, 'session-xyz');
      expect(trackingService.currentActivityType, ActivityType.READING);
      expect(fakeRepo.sessionStarted, isTrue);
      expect(fakeRepo.lastStartRequest?.bookId, 'book-123');

      // Update progress
      trackingService.updateProgress(
        currentLocation: 'page=15',
        currentPage: 15,
      );

      await trackingService.closeSession();

      expect(trackingService.hasActiveSession, isFalse);
      expect(fakeRepo.sessionClosed, isTrue);
      expect(fakeRepo.lastCloseRequest?.endingLocation, 'page=15');
      expect(fakeRepo.lastCloseRequest?.endingPage, 15);
      expect(fakeRepo.lastCloseRequest?.pagesReadDelta, 5);
    });

    test('starts audiobook and updates speed', () async {
      await trackingService.startSession(
        activityType: ActivityType.AUDIOBOOK,
        bookId: 'book-audio-1',
        playbackSpeed: 1.25,
      );

      expect(trackingService.currentActivityType, ActivityType.AUDIOBOOK);
      expect(fakeRepo.lastStartRequest?.playbackSpeed, 1.25);

      trackingService.updateProgress(playbackSpeed: 1.5);
      await trackingService.closeSession();
      expect(trackingService.hasActiveSession, isFalse);
    });
  });
}

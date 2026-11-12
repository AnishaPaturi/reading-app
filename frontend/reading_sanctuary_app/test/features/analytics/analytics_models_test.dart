import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/activity_session.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/analytics_overview.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/author_analytics.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/daily_activity.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/genre_analytics.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/goal_progress.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/listening_analytics.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/reading_goal.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/reading_pace.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/reading_streak.dart';
import 'package:reading_sanctuary_app/features/analytics/data/models/yearly_wrap_up.dart';

void main() {
  group('Analytics Models Test', () {
    test('ActivitySessionRequest and Response JSON', () {
      final req = const ActivitySessionRequest(
        activityType: ActivityType.READING,
        bookId: 'b-1',
        bookFileId: 'f-1',
        startingLocation: 'page=1',
        startingPage: 1,
        playbackSpeed: 1.0,
      );
      final jsonReq = req.toJson();
      expect(jsonReq['activityType'], 'READING');
      expect(jsonReq['bookId'], 'b-1');

      final res = ActivitySessionResponse.fromJson({
        'id': 'sess-123',
        'activityType': 'READING',
        'bookId': 'b-1',
        'bookTitle': 'Dune',
        'durationSeconds': 1800,
        'pagesRead': 25,
        'active': true,
      });
      expect(res.id, 'sess-123');
      expect(res.activityType, ActivityType.READING);
      expect(res.bookTitle, 'Dune');
      expect(res.durationSeconds, 1800);
      expect(res.pagesRead, 25);
      expect(res.active, isTrue);
    });

    test('ReadingGoalRequest and Response JSON', () {
      final req = const ReadingGoalRequest(
        goalType: GoalType.READING_MINUTES,
        targetValue: 30,
        periodType: GoalPeriod.DAILY,
        startDate: '2026-11-09',
        endDate: '2026-11-09',
      );
      expect(req.toJson()['targetValue'], 30);
      expect(req.toJson()['goalType'], 'READING_MINUTES');

      final res = ReadingGoalResponse.fromJson({
        'id': 'goal-1',
        'goalType': 'BOOKS_COMPLETED',
        'targetValue': 24,
        'periodType': 'YEARLY',
        'startDate': '2026-01-01',
        'endDate': '2026-12-31',
        'active': true,
      });
      expect(res.id, 'goal-1');
      expect(res.goalType, GoalType.BOOKS_COMPLETED);
      expect(res.targetValue, 24);
      expect(res.periodType, GoalPeriod.YEARLY);
      expect(res.active, isTrue);
    });

    test('GoalProgressResponse JSON', () {
      final progress = GoalProgressResponse.fromJson({
        'goalId': 'g-1',
        'goalType': 'READING_MINUTES',
        'periodType': 'DAILY',
        'targetValue': 60,
        'currentValue': 45,
        'percentage': 75.0,
        'remainingValue': 15,
        'completed': false,
        'message': '15 mins remaining today',
      });
      expect(progress.currentValue, 45);
      expect(progress.targetValue, 60);
      expect(progress.percentage, 75.0);
      expect(progress.remainingValue, 15);
      expect(progress.completed, isFalse);
    });

    test('AnalyticsOverviewResponse calculations', () {
      final overview = AnalyticsOverviewResponse.fromJson({
        'totalBooks': 10,
        'completedBooks': 4,
        'currentlyReadingBooks': 2,
        'tbrBooks': 3,
        'dnfBooks': 1,
        'totalReadingMinutes': 300,
        'totalAudiobookMinutes': 120,
        'totalTtsMinutes': 60,
        'activeReadingDays': 15,
        'currentStreakDays': 5,
        'booksCompletedThisYear': 4,
      });
      expect(overview.totalBooks, 10);
      expect(overview.totalReadingMinutes, 300);
      expect(overview.totalAudiobookMinutes, 120);
      expect(overview.totalTtsMinutes, 60);
      expect(overview.totalListeningMinutes, 180);
      expect(overview.totalAllMinutes, 480);
    });

    test('DailyActivityResponse and Items', () {
      final daily = DailyActivityResponse.fromJson({
        'period': 'WEEK',
        'startDate': '2026-11-02',
        'endDate': '2026-11-08',
        'totalReadingMinutes': 120,
        'totalAudiobookMinutes': 60,
        'totalTtsMinutes': 30,
        'totalMinutes': 210,
        'dailyBreakdown': [
          {
            'date': '2026-11-02',
            'readingMinutes': 40,
            'audiobookMinutes': 20,
            'ttsMinutes': 10,
            'totalMinutes': 70,
            'pagesRead': 15,
          }
        ],
      });
      expect(daily.period, 'WEEK');
      expect(daily.totalMinutes, 210);
      expect(daily.dailyBreakdown.length, 1);
      expect(daily.dailyBreakdown.first.listeningMinutes, 30);
    });

    test('StreakResponse and ReadingPaceResponse', () {
      final streak = StreakResponse.fromJson({
        'currentStreakDays': 7,
        'longestStreakDays': 21,
        'lastActiveDate': '2026-11-09',
        'activeDatesThisYear': ['2026-11-08', '2026-11-09'],
        'totalActiveDaysThisYear': 2,
      });
      expect(streak.currentStreakDays, 7);
      expect(streak.longestStreakDays, 21);
      expect(streak.activeDatesThisYear.length, 2);

      final pace = ReadingPaceResponse.fromJson({
        'averageMinutesPerDay': 42.5,
        'averagePagesPerDay': 30.0,
        'averageMinutesPerSession': 25.0,
        'totalSessions': 18,
        'estimatedCompletionDaysCurrentBook': 4,
      });
      expect(pace.averageMinutesPerDay, 42.5);
      expect(pace.estimatedCompletionDaysCurrentBook, 4);
    });

    test('ListeningAnalyticsResponse and YearlyWrapUpResponse', () {
      final listening = ListeningAnalyticsResponse.fromJson({
        'totalListeningMinutes': 300,
        'audiobookMinutes': 200,
        'ttsMinutes': 100,
        'audiobookPercentage': 66.7,
        'ttsPercentage': 33.3,
        'audiobooksCompleted': 2,
        'totalAudiobookSessions': 8,
        'totalTtsSessions': 4,
        'averageListeningSpeed': 1.25,
      });
      expect(listening.totalListeningMinutes, 300);
      expect(listening.audiobookMinutes, 200);
      expect(listening.ttsMinutes, 100);
      expect(listening.averageListeningSpeed, 1.25);

      final wrapUp = YearlyWrapUpResponse.fromJson({
        'year': 2026,
        'totalBooksCompleted': 12,
        'totalReadingMinutes': 3600,
        'totalAudiobookMinutes': 1200,
        'totalTtsMinutes': 600,
        'longestStreakDays': 30,
        'activeReadingDays': 180,
        'favoriteGenre': 'Science Fiction',
        'topAuthor': 'Frank Herbert',
      });
      expect(wrapUp.year, 2026);
      expect(wrapUp.totalBooksCompleted, 12);
      expect(wrapUp.favoriteGenre, 'Science Fiction');
      expect(wrapUp.topAuthor, 'Frank Herbert');
      expect(wrapUp.totalAllMinutes, 5400);
    });

    test('GenreAnalytics and AuthorAnalytics JSON', () {
      final genres = GenreAnalyticsResponse.fromJson({
        'totalCategorizedBooks': 5,
        'topGenres': [
          {'genre': 'Fantasy', 'bookCount': 3, 'percentage': 60.0, 'readingMinutes': 400},
          {'genre': 'Sci-Fi', 'bookCount': 2, 'percentage': 40.0, 'readingMinutes': 250},
        ],
      });
      expect(genres.totalCategorizedBooks, 5);
      expect(genres.topGenres.length, 2);
      expect(genres.topGenres.first.genre, 'Fantasy');

      final authors = AuthorAnalyticsResponse.fromJson({
        'totalAuthors': 2,
        'topAuthors': [
          {'author': 'Brandon Sanderson', 'bookCount': 4, 'completedCount': 3, 'readingMinutes': 800},
        ],
      });
      expect(authors.totalAuthors, 2);
      expect(authors.topAuthors.first.author, 'Brandon Sanderson');
    });
  });
}

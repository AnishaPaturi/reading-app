import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/activity_session.dart';
import '../models/analytics_overview.dart';
import '../models/author_analytics.dart';
import '../models/books_completed.dart';
import '../models/daily_activity.dart';
import '../models/genre_analytics.dart';
import '../models/goal_progress.dart';
import '../models/listening_analytics.dart';
import '../models/reading_goal.dart';
import '../models/reading_pace.dart';
import '../models/reading_streak.dart';
import '../models/yearly_wrap_up.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsOverviewResponse> getOverview({DateTime? from, DateTime? to, String? timezone});
  Future<DailyActivityResponse> getActivity({String period = 'MONTH', int? year, int? month, String? timezone});
  Future<StreakResponse> getStreaks({String? timezone});
  Future<ReadingPaceResponse> getReadingPace({int? year, DateTime? from, DateTime? to});
  Future<BooksCompletedResponse> getBooksCompleted({int? year});
  Future<GenreAnalyticsResponse> getGenres({int? year});
  Future<AuthorAnalyticsResponse> getAuthors({int? year});
  Future<ListeningAnalyticsResponse> getListening({int? year});
  Future<YearlyWrapUpResponse> getYearlyWrapUp({int? year});

  Future<List<ReadingGoalResponse>> getGoals({bool? activeOnly});
  Future<ReadingGoalResponse> createGoal(ReadingGoalRequest request);
  Future<ReadingGoalResponse> updateGoal(String goalId, ReadingGoalRequest request);
  Future<void> deleteGoal(String goalId);
  Future<GoalProgressResponse> getGoalProgress(String goalId);

  Future<ActivitySessionResponse> startSession(ActivitySessionRequest request);
  Future<ActivitySessionResponse> sendHeartbeat(String sessionId, ActivityHeartbeatRequest request);
  Future<ActivitySessionResponse> closeSession(String sessionId, CloseSessionRequest request);
  Future<List<ActivitySessionResponse>> getSessionHistory({int page = 0, int size = 20});
}

class HttpAnalyticsRepository implements AnalyticsRepository {
  final String baseUrl;
  final String? Function() tokenProvider;

  HttpAnalyticsRepository({
    String? baseUrl,
    required this.tokenProvider,
  }) : baseUrl = baseUrl ?? _resolveBaseUrl();

  static String _resolveBaseUrl() {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080/api/v1';
    return 'http://localhost:8080/api/v1';
  }

  Map<String, String> _headers() {
    final token = tokenProvider();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<AnalyticsOverviewResponse> getOverview({DateTime? from, DateTime? to, String? timezone}) async {
    final uri = Uri.parse('$baseUrl/analytics/overview').replace(queryParameters: {
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
      if (timezone != null) 'timezone': timezone,
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return AnalyticsOverviewResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return const AnalyticsOverviewResponse(
      totalBooks: 0,
      completedBooks: 0,
      currentlyReadingBooks: 0,
      tbrBooks: 0,
      dnfBooks: 0,
      totalReadingMinutes: 0,
      totalAudiobookMinutes: 0,
      totalTtsMinutes: 0,
      activeReadingDays: 0,
      currentStreakDays: 0,
      booksCompletedThisYear: 0,
    );
  }

  @override
  Future<DailyActivityResponse> getActivity({String period = 'MONTH', int? year, int? month, String? timezone}) async {
    final uri = Uri.parse('$baseUrl/analytics/activity').replace(queryParameters: {
      'period': period,
      if (year != null) 'year': year.toString(),
      if (month != null) 'month': month.toString(),
      if (timezone != null) 'timezone': timezone,
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return DailyActivityResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return DailyActivityResponse(
      period: period,
      startDate: '',
      endDate: '',
      totalReadingMinutes: 0,
      totalAudiobookMinutes: 0,
      totalTtsMinutes: 0,
      totalMinutes: 0,
      dailyBreakdown: const [],
    );
  }

  @override
  Future<StreakResponse> getStreaks({String? timezone}) async {
    final uri = Uri.parse('$baseUrl/analytics/streaks').replace(queryParameters: {
      if (timezone != null) 'timezone': timezone,
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return StreakResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return const StreakResponse(
      currentStreakDays: 0,
      longestStreakDays: 0,
      activeDatesThisYear: [],
      totalActiveDaysThisYear: 0,
    );
  }

  @override
  Future<ReadingPaceResponse> getReadingPace({int? year, DateTime? from, DateTime? to}) async {
    final uri = Uri.parse('$baseUrl/analytics/pace').replace(queryParameters: {
      if (year != null) 'year': year.toString(),
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return ReadingPaceResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return const ReadingPaceResponse(
      averageMinutesPerDay: 0,
      averagePagesPerDay: 0,
      averageMinutesPerSession: 0,
      totalSessions: 0,
    );
  }

  @override
  Future<BooksCompletedResponse> getBooksCompleted({int? year}) async {
    final uri = Uri.parse('$baseUrl/analytics/books-completed').replace(queryParameters: {
      if (year != null) 'year': year.toString(),
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return BooksCompletedResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return BooksCompletedResponse(
      year: year ?? DateTime.now().year,
      totalCompleted: 0,
      monthlyBreakdown: const [],
    );
  }

  @override
  Future<GenreAnalyticsResponse> getGenres({int? year}) async {
    final uri = Uri.parse('$baseUrl/analytics/genres').replace(queryParameters: {
      if (year != null) 'year': year.toString(),
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return GenreAnalyticsResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return const GenreAnalyticsResponse(
      totalCategorizedBooks: 0,
      topGenres: [],
    );
  }

  @override
  Future<AuthorAnalyticsResponse> getAuthors({int? year}) async {
    final uri = Uri.parse('$baseUrl/analytics/authors').replace(queryParameters: {
      if (year != null) 'year': year.toString(),
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return AuthorAnalyticsResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return const AuthorAnalyticsResponse(
      totalAuthors: 0,
      topAuthors: [],
    );
  }

  @override
  Future<ListeningAnalyticsResponse> getListening({int? year}) async {
    final uri = Uri.parse('$baseUrl/analytics/listening').replace(queryParameters: {
      if (year != null) 'year': year.toString(),
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return ListeningAnalyticsResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return const ListeningAnalyticsResponse(
      totalListeningMinutes: 0,
      audiobookMinutes: 0,
      ttsMinutes: 0,
      audiobookPercentage: 0,
      ttsPercentage: 0,
      audiobooksCompleted: 0,
      totalAudiobookSessions: 0,
      totalTtsSessions: 0,
      averageListeningSpeed: 1.0,
    );
  }

  @override
  Future<YearlyWrapUpResponse> getYearlyWrapUp({int? year}) async {
    final uri = Uri.parse('$baseUrl/analytics/wrap-up').replace(queryParameters: {
      if (year != null) 'year': year.toString(),
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      return YearlyWrapUpResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    return YearlyWrapUpResponse(
      year: year ?? DateTime.now().year,
      totalBooksCompleted: 0,
      totalReadingMinutes: 0,
      totalAudiobookMinutes: 0,
      totalTtsMinutes: 0,
      longestStreakDays: 0,
      activeReadingDays: 0,
    );
  }

  @override
  Future<List<ReadingGoalResponse>> getGoals({bool? activeOnly}) async {
    final uri = Uri.parse('$baseUrl/analytics/goals').replace(queryParameters: {
      if (activeOnly != null) 'activeOnly': activeOnly.toString(),
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => ReadingGoalResponse.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }

  @override
  Future<ReadingGoalResponse> createGoal(ReadingGoalRequest request) async {
    final res = await http.post(
      Uri.parse('$baseUrl/analytics/goals'),
      headers: _headers(),
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return ReadingGoalResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create goal: ${res.statusCode} ${res.body}');
  }

  @override
  Future<ReadingGoalResponse> updateGoal(String goalId, ReadingGoalRequest request) async {
    final res = await http.put(
      Uri.parse('$baseUrl/analytics/goals/$goalId'),
      headers: _headers(),
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 200) {
      return ReadingGoalResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update goal: ${res.statusCode} ${res.body}');
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/analytics/goals/$goalId'),
      headers: _headers(),
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Failed to delete goal: ${res.statusCode}');
    }
  }

  @override
  Future<GoalProgressResponse> getGoalProgress(String goalId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/analytics/goals/$goalId/progress'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      return GoalProgressResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch goal progress: ${res.statusCode}');
  }

  @override
  Future<ActivitySessionResponse> startSession(ActivitySessionRequest request) async {
    final res = await http.post(
      Uri.parse('$baseUrl/analytics/sessions/start'),
      headers: _headers(),
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return ActivitySessionResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to start session: ${res.statusCode} ${res.body}');
  }

  @override
  Future<ActivitySessionResponse> sendHeartbeat(String sessionId, ActivityHeartbeatRequest request) async {
    final res = await http.post(
      Uri.parse('$baseUrl/analytics/sessions/$sessionId/heartbeat'),
      headers: _headers(),
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 200) {
      return ActivitySessionResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to send heartbeat: ${res.statusCode} ${res.body}');
  }

  @override
  Future<ActivitySessionResponse> closeSession(String sessionId, CloseSessionRequest request) async {
    final res = await http.post(
      Uri.parse('$baseUrl/analytics/sessions/$sessionId/close'),
      headers: _headers(),
      body: jsonEncode(request.toJson()),
    );
    if (res.statusCode == 200) {
      return ActivitySessionResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to close session: ${res.statusCode} ${res.body}');
  }

  @override
  Future<List<ActivitySessionResponse>> getSessionHistory({int page = 0, int size = 20}) async {
    final uri = Uri.parse('$baseUrl/analytics/sessions/history').replace(queryParameters: {
      'page': page.toString(),
      'size': size.toString(),
    });
    final res = await http.get(uri, headers: _headers());
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.map((e) => ActivitySessionResponse.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }
}

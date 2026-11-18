class WeeklyDayStatus {
  final String date;
  final String dayOfWeek;
  final bool isCompleted;
  final bool isToday;
  final bool isFuture;
  final int minutesRead;

  const WeeklyDayStatus({
    required this.date,
    required this.dayOfWeek,
    required this.isCompleted,
    required this.isToday,
    required this.isFuture,
    required this.minutesRead,
  });

  factory WeeklyDayStatus.fromJson(Map<String, dynamic> json) {
    return WeeklyDayStatus(
      date: json['date']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true,
      isToday: json['isToday'] == true,
      isFuture: json['isFuture'] == true,
      minutesRead: (json['minutesRead'] as num?)?.toInt() ?? 0,
    );
  }
}

class StreakResponse {
  final int currentStreakDays;
  final int longestStreakDays;
  final String? lastActiveDate; // yyyy-MM-dd
  final List<String> activeDatesThisYear;
  final int totalActiveDaysThisYear;
  final bool isTodayComplete;
  final int freezesAvailable;
  final int freezesUsed;
  final List<String> frozenDays;
  final int momentumDaysActiveLast7;
  final String momentumStatus;
  final List<WeeklyDayStatus> weeklyActivity;

  const StreakResponse({
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.lastActiveDate,
    required this.activeDatesThisYear,
    required this.totalActiveDaysThisYear,
    this.isTodayComplete = false,
    this.freezesAvailable = 2,
    this.freezesUsed = 0,
    this.frozenDays = const [],
    this.momentumDaysActiveLast7 = 0,
    this.momentumStatus = 'Starting',
    this.weeklyActivity = const [],
  });

  factory StreakResponse.fromJson(Map<String, dynamic> json) {
    final rawDates = json['activeDays'] ?? json['activeDatesThisYear'];
    final dates = (rawDates as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final rawFrozen = json['frozenDays'] as List<dynamic>? ?? [];
    final frozen = rawFrozen.map((e) => e.toString()).toList();

    final rawWeekly = json['weeklyActivity'] as List<dynamic>? ?? [];
    final weekly = rawWeekly
        .whereType<Map<String, dynamic>>()
        .map((w) => WeeklyDayStatus.fromJson(w))
        .toList();

    return StreakResponse(
      currentStreakDays: ((json['currentStreak'] ?? json['currentStreakDays']) as num?)?.toInt() ?? 0,
      longestStreakDays: ((json['longestStreak'] ?? json['longestStreakDays']) as num?)?.toInt() ?? 0,
      lastActiveDate: json['lastActiveDate']?.toString(),
      activeDatesThisYear: dates,
      totalActiveDaysThisYear: (json['totalActiveDaysThisYear'] as num?)?.toInt() ?? dates.length,
      isTodayComplete: json['isTodayComplete'] == true,
      freezesAvailable: (json['freezesAvailable'] as num?)?.toInt() ?? 2,
      freezesUsed: (json['freezesUsed'] as num?)?.toInt() ?? 0,
      frozenDays: frozen,
      momentumDaysActiveLast7: (json['momentumDaysActiveLast7'] as num?)?.toInt() ?? 0,
      momentumStatus: json['momentumStatus']?.toString() ?? 'Starting',
      weeklyActivity: weekly,
    );
  }
}

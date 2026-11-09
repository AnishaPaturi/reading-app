class StreakResponse {
  final int currentStreakDays;
  final int longestStreakDays;
  final String? lastActiveDate; // yyyy-MM-dd
  final List<String> activeDatesThisYear;
  final int totalActiveDaysThisYear;

  const StreakResponse({
    required this.currentStreakDays,
    required this.longestStreakDays,
    this.lastActiveDate,
    required this.activeDatesThisYear,
    required this.totalActiveDaysThisYear,
  });

  factory StreakResponse.fromJson(Map<String, dynamic> json) {
    final dates = (json['activeDatesThisYear'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    return StreakResponse(
      currentStreakDays: (json['currentStreakDays'] as num?)?.toInt() ?? 0,
      longestStreakDays: (json['longestStreakDays'] as num?)?.toInt() ?? 0,
      lastActiveDate: json['lastActiveDate']?.toString(),
      activeDatesThisYear: dates,
      totalActiveDaysThisYear: (json['totalActiveDaysThisYear'] as num?)?.toInt() ?? 0,
    );
  }
}

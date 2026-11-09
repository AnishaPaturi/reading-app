class DailyActivityItem {
  final String date; // yyyy-MM-dd
  final int readingMinutes;
  final int audiobookMinutes;
  final int ttsMinutes;
  final int totalMinutes;
  final int pagesRead;

  const DailyActivityItem({
    required this.date,
    required this.readingMinutes,
    required this.audiobookMinutes,
    required this.ttsMinutes,
    required this.totalMinutes,
    required this.pagesRead,
  });

  int get listeningMinutes => audiobookMinutes + ttsMinutes;

  factory DailyActivityItem.fromJson(Map<String, dynamic> json) {
    return DailyActivityItem(
      date: json['date']?.toString() ?? '',
      readingMinutes: (json['readingMinutes'] as num?)?.toInt() ?? 0,
      audiobookMinutes: (json['audiobookMinutes'] as num?)?.toInt() ?? 0,
      ttsMinutes: (json['ttsMinutes'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      pagesRead: (json['pagesRead'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyActivityResponse {
  final String period;
  final String startDate;
  final String endDate;
  final int totalReadingMinutes;
  final int totalAudiobookMinutes;
  final int totalTtsMinutes;
  final int totalMinutes;
  final List<DailyActivityItem> dailyBreakdown;

  const DailyActivityResponse({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.totalReadingMinutes,
    required this.totalAudiobookMinutes,
    required this.totalTtsMinutes,
    required this.totalMinutes,
    required this.dailyBreakdown,
  });

  factory DailyActivityResponse.fromJson(Map<String, dynamic> json) {
    final list = json['dailyBreakdown'] as List<dynamic>? ?? [];
    return DailyActivityResponse(
      period: json['period']?.toString() ?? 'MONTH',
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      totalReadingMinutes: (json['totalReadingMinutes'] as num?)?.toInt() ?? 0,
      totalAudiobookMinutes: (json['totalAudiobookMinutes'] as num?)?.toInt() ?? 0,
      totalTtsMinutes: (json['totalTtsMinutes'] as num?)?.toInt() ?? 0,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      dailyBreakdown: list.map((item) => DailyActivityItem.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

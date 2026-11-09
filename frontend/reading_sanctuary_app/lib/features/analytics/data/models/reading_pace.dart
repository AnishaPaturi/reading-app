class ReadingPaceResponse {
  final double averageMinutesPerDay;
  final double averagePagesPerDay;
  final double averageMinutesPerSession;
  final int totalSessions;
  final int? estimatedCompletionDaysCurrentBook;

  const ReadingPaceResponse({
    required this.averageMinutesPerDay,
    required this.averagePagesPerDay,
    required this.averageMinutesPerSession,
    required this.totalSessions,
    this.estimatedCompletionDaysCurrentBook,
  });

  factory ReadingPaceResponse.fromJson(Map<String, dynamic> json) {
    return ReadingPaceResponse(
      averageMinutesPerDay: (json['averageMinutesPerDay'] as num?)?.toDouble() ?? 0.0,
      averagePagesPerDay: (json['averagePagesPerDay'] as num?)?.toDouble() ?? 0.0,
      averageMinutesPerSession: (json['averageMinutesPerSession'] as num?)?.toDouble() ?? 0.0,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      estimatedCompletionDaysCurrentBook: (json['estimatedCompletionDaysCurrentBook'] as num?)?.toInt(),
    );
  }
}

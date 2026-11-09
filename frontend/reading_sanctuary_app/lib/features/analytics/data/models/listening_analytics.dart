class ListeningAnalyticsResponse {
  final int totalListeningMinutes;
  final int audiobookMinutes;
  final int ttsMinutes;
  final double audiobookPercentage;
  final double ttsPercentage;
  final int audiobooksCompleted;
  final int totalAudiobookSessions;
  final int totalTtsSessions;
  final double averageListeningSpeed;

  const ListeningAnalyticsResponse({
    required this.totalListeningMinutes,
    required this.audiobookMinutes,
    required this.ttsMinutes,
    required this.audiobookPercentage,
    required this.ttsPercentage,
    required this.audiobooksCompleted,
    required this.totalAudiobookSessions,
    required this.totalTtsSessions,
    required this.averageListeningSpeed,
  });

  factory ListeningAnalyticsResponse.fromJson(Map<String, dynamic> json) {
    return ListeningAnalyticsResponse(
      totalListeningMinutes: (json['totalListeningMinutes'] as num?)?.toInt() ?? 0,
      audiobookMinutes: (json['audiobookMinutes'] as num?)?.toInt() ?? 0,
      ttsMinutes: (json['ttsMinutes'] as num?)?.toInt() ?? 0,
      audiobookPercentage: (json['audiobookPercentage'] as num?)?.toDouble() ?? 0.0,
      ttsPercentage: (json['ttsPercentage'] as num?)?.toDouble() ?? 0.0,
      audiobooksCompleted: (json['audiobooksCompleted'] as num?)?.toInt() ?? 0,
      totalAudiobookSessions: (json['totalAudiobookSessions'] as num?)?.toInt() ?? 0,
      totalTtsSessions: (json['totalTtsSessions'] as num?)?.toInt() ?? 0,
      averageListeningSpeed: (json['averageListeningSpeed'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

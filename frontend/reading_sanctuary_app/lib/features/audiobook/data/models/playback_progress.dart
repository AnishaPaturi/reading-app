class PlaybackProgress {
  final String audiobookId;
  final String? currentTrackId;
  final int trackIndex;
  final int positionMs;
  final int totalDurationMs;
  final double playbackSpeed;
  final DateTime lastListenedAt;
  final bool completed;

  const PlaybackProgress({
    required this.audiobookId,
    this.currentTrackId,
    required this.trackIndex,
    required this.positionMs,
    required this.totalDurationMs,
    required this.playbackSpeed,
    required this.lastListenedAt,
    required this.completed,
  });

  PlaybackProgress copyWith({
    String? audiobookId,
    String? currentTrackId,
    int? trackIndex,
    int? positionMs,
    int? totalDurationMs,
    double? playbackSpeed,
    DateTime? lastListenedAt,
    bool? completed,
  }) {
    return PlaybackProgress(
      audiobookId: audiobookId ?? this.audiobookId,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      trackIndex: trackIndex ?? this.trackIndex,
      positionMs: positionMs ?? this.positionMs,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      lastListenedAt: lastListenedAt ?? this.lastListenedAt,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'audiobookId': audiobookId,
      'currentTrackId': currentTrackId,
      'trackIndex': trackIndex,
      'positionMs': positionMs,
      'totalDurationMs': totalDurationMs,
      'playbackSpeed': playbackSpeed,
      'lastListenedAt': lastListenedAt.toIso8601String(),
      'completed': completed,
    };
  }

  factory PlaybackProgress.fromJson(Map<String, dynamic> json) {
    return PlaybackProgress(
      audiobookId: json['audiobookId'] as String,
      currentTrackId: json['currentTrackId'] as String?,
      trackIndex: (json['trackIndex'] as num?)?.toInt() ?? 0,
      positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
      totalDurationMs: (json['totalDurationMs'] as num?)?.toInt() ?? 0,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      lastListenedAt: json['lastListenedAt'] != null
          ? DateTime.tryParse(json['lastListenedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      completed: json['completed'] as bool? ?? false,
    );
  }
}

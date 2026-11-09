class AudioPosition {
  final int positionMs;
  final int durationMs;
  final double playbackSpeed;
  final bool isCompleted;
  final DateTime updatedAt;

  const AudioPosition({
    required this.positionMs,
    required this.durationMs,
    required this.playbackSpeed,
    this.isCompleted = false,
    required this.updatedAt,
  });

  factory AudioPosition.fromJson(Map<String, dynamic> json) {
    return AudioPosition(
      positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      playbackSpeed: (json['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'positionMs': positionMs,
      'durationMs': durationMs,
      'playbackSpeed': playbackSpeed,
      'isCompleted': isCompleted,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AudioPosition copyWith({
    int? positionMs,
    int? durationMs,
    double? playbackSpeed,
    bool? isCompleted,
    DateTime? updatedAt,
  }) {
    return AudioPosition(
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isCompleted: isCompleted ?? this.isCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

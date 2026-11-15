class ListeningSession {
  final String id;
  final String audiobookId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int actualListeningMs;

  const ListeningSession({
    required this.id,
    required this.audiobookId,
    required this.startedAt,
    this.endedAt,
    this.actualListeningMs = 0,
  });

  ListeningSession copyWith({
    String? id,
    String? audiobookId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? actualListeningMs,
  }) {
    return ListeningSession(
      id: id ?? this.id,
      audiobookId: audiobookId ?? this.audiobookId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      actualListeningMs: actualListeningMs ?? this.actualListeningMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audiobookId': audiobookId,
      'startedAt': startedAt.toIso8601String(),
      if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
      'actualListeningMs': actualListeningMs,
    };
  }

  factory ListeningSession.fromJson(Map<String, dynamic> json) {
    return ListeningSession(
      id: json['id'] as String,
      audiobookId: json['audiobookId'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.tryParse(json['endedAt'] as String)
          : null,
      actualListeningMs: (json['actualListeningMs'] as num?)?.toInt() ?? 0,
    );
  }
}

class ListeningEvent {
  final String id;
  final String sessionId;
  final String eventType; // 'play', 'pause', 'seekForward', 'seekBackward', 'trackChanged', 'completed'
  final int trackIndex;
  final int positionMs;
  final DateTime createdAt;

  const ListeningEvent({
    required this.id,
    required this.sessionId,
    required this.eventType,
    required this.trackIndex,
    required this.positionMs,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'eventType': eventType,
      'trackIndex': trackIndex,
      'positionMs': positionMs,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ListeningEvent.fromJson(Map<String, dynamic> json) {
    return ListeningEvent(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      eventType: json['eventType'] as String,
      trackIndex: (json['trackIndex'] as num?)?.toInt() ?? 0,
      positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

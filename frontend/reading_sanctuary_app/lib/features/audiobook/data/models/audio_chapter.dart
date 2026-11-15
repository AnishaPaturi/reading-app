class AudioChapter {
  final String id;
  final String? audiobookId;
  final String? trackId;
  final String title;
  final Duration start;
  final Duration end;

  const AudioChapter({
    required this.id,
    this.audiobookId,
    this.trackId,
    required this.title,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (audiobookId != null) 'audiobookId': audiobookId,
      if (trackId != null) 'trackId': trackId,
      'title': title,
      'startMs': start.inMilliseconds,
      'endMs': end.inMilliseconds,
    };
  }

  factory AudioChapter.fromJson(Map<String, dynamic> json) {
    return AudioChapter(
      id: json['id'] as String,
      audiobookId: json['audiobookId'] as String?,
      trackId: json['trackId'] as String?,
      title: json['title'] as String? ?? 'Chapter',
      start: Duration(milliseconds: (json['startMs'] as num?)?.toInt() ?? 0),
      end: Duration(milliseconds: (json['endMs'] as num?)?.toInt() ?? 0),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioChapter &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class AudiobookBookmark {
  final String id;
  final String audiobookId;
  final String? trackId;
  final int trackIndex;
  final int positionMs;
  final String title;
  final String? note;
  final String category; // 'quote', 'note', 'revisit'
  final bool isFavorite;
  final DateTime createdAt;

  const AudiobookBookmark({
    required this.id,
    required this.audiobookId,
    this.trackId,
    this.trackIndex = 0,
    required this.positionMs,
    required this.title,
    this.note,
    this.category = 'note',
    this.isFavorite = false,
    required this.createdAt,
  });

  AudiobookBookmark copyWith({
    String? id,
    String? audiobookId,
    String? trackId,
    int? trackIndex,
    int? positionMs,
    String? title,
    String? note,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return AudiobookBookmark(
      id: id ?? this.id,
      audiobookId: audiobookId ?? this.audiobookId,
      trackId: trackId ?? this.trackId,
      trackIndex: trackIndex ?? this.trackIndex,
      positionMs: positionMs ?? this.positionMs,
      title: title ?? this.title,
      note: note ?? this.note,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audiobookId': audiobookId,
      if (trackId != null) 'trackId': trackId,
      'trackIndex': trackIndex,
      'positionMs': positionMs,
      'title': title,
      if (note != null) 'note': note,
      'category': category,
      'isFavorite': isFavorite,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AudiobookBookmark.fromJson(Map<String, dynamic> json) {
    return AudiobookBookmark(
      id: json['id'] as String,
      audiobookId: json['audiobookId'] as String,
      trackId: json['trackId'] as String?,
      trackIndex: (json['trackIndex'] as num?)?.toInt() ?? 0,
      positionMs: (json['positionMs'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled Bookmark',
      note: json['note'] as String?,
      category: json['category'] as String? ?? 'note',
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

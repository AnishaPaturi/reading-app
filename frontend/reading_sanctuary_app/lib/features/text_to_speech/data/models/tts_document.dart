class TtsChunk {
  final int index;
  final String text;

  const TtsChunk({
    required this.index,
    required this.text,
  });

  factory TtsChunk.fromJson(Map<String, dynamic> json) {
    return TtsChunk(
      index: (json['index'] as num?)?.toInt() ?? 0,
      text: (json['text'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'text': text,
    };
  }
}

class TtsDocument {
  final String bookId;
  final String bookFileId;
  final String format;
  final int chapter;
  final String title;
  final List<TtsChunk> chunks;
  final bool hasNextChapter;

  const TtsDocument({
    required this.bookId,
    required this.bookFileId,
    required this.format,
    required this.chapter,
    required this.title,
    required this.chunks,
    required this.hasNextChapter,
  });

  factory TtsDocument.fromJson(Map<String, dynamic> json) {
    final rawChunks = json['chunks'] as List<dynamic>? ?? [];
    return TtsDocument(
      bookId: (json['bookId'] as String?) ?? '',
      bookFileId: (json['bookFileId'] as String?) ?? '',
      format: (json['format'] as String?) ?? '',
      chapter: (json['chapter'] as num?)?.toInt() ?? 1,
      title: (json['title'] as String?) ?? 'Chapter',
      chunks: rawChunks
          .map((c) => TtsChunk.fromJson(c as Map<String, dynamic>))
          .toList(),
      hasNextChapter: json['hasNextChapter'] as bool? ?? false,
    );
  }
}

class TtsPosition {
  final int chapterIndex;
  final int chunkIndex;
  final int characterOffset;
  final double progressPercentage;
  final DateTime updatedAt;

  const TtsPosition({
    this.chapterIndex = 0,
    this.chunkIndex = 0,
    this.characterOffset = 0,
    this.progressPercentage = 0.0,
    required this.updatedAt,
  });

  factory TtsPosition.fromJson(Map<String, dynamic> json) {
    return TtsPosition(
      chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 0,
      chunkIndex: (json['chunkIndex'] as num?)?.toInt() ?? 0,
      characterOffset: (json['characterOffset'] as num?)?.toInt() ?? 0,
      progressPercentage:
          (json['progressPercentage'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterIndex': chapterIndex,
      'chunkIndex': chunkIndex,
      'characterOffset': characterOffset,
      'progressPercentage': progressPercentage,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  TtsPosition copyWith({
    int? chapterIndex,
    int? chunkIndex,
    int? characterOffset,
    double? progressPercentage,
    DateTime? updatedAt,
  }) {
    return TtsPosition(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chunkIndex: chunkIndex ?? this.chunkIndex,
      characterOffset: characterOffset ?? this.characterOffset,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

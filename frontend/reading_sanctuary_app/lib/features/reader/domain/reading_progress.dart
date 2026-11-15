class ReadingProgress {
  final String bookFileId;
  final String format;

  final int? currentPage;
  final int? totalPages;

  final String? chapterHref;
  final String? epubCfi;

  final int? audioPositionMs;
  final int? audioDurationMs;

  final double progressPercentage;

  final Map<String, dynamic> positionData;

  final DateTime? lastOpenedAt;
  final DateTime? updatedAt;

  const ReadingProgress({
    required this.bookFileId,
    required this.format,
    this.currentPage,
    this.totalPages,
    this.chapterHref,
    this.epubCfi,
    this.audioPositionMs,
    this.audioDurationMs,
    this.progressPercentage = 0,
    this.positionData = const {},
    this.lastOpenedAt,
    this.updatedAt,
  });

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    int? parseOptionalInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    double parseDouble(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    Map<String, dynamic> parsePositionData(dynamic value) {
      if (value == null) return {};
      if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
      if (value is Map) return Map<String, dynamic>.from(value);
      if (value is String) {
        try {
          return Map<String, dynamic>.from(
            Map<dynamic, dynamic>.from(const {}),
          );
        } catch (_) {
          return {};
        }
      }
      return {};
    }

    return ReadingProgress(
      bookFileId: json['bookFileId']?.toString() ?? '',
      format: json['format']?.toString() ?? 'PDF',
      currentPage: parseOptionalInt(json['currentPage']),
      totalPages: parseOptionalInt(json['totalPages']),
      chapterHref: json['chapterHref']?.toString(),
      epubCfi: json['epubCfi']?.toString(),
      audioPositionMs: parseOptionalInt(json['audioPositionMs']),
      audioDurationMs: parseOptionalInt(json['audioDurationMs']),
      progressPercentage: parseDouble(json['progressPercentage']),
      positionData: parsePositionData(json['positionData']),
      lastOpenedAt: parseDateTime(json['lastOpenedAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'chapterHref': chapterHref,
      'epubCfi': epubCfi,
      'audioPositionMs': audioPositionMs,
      'audioDurationMs': audioDurationMs,
      'progressPercentage': progressPercentage,
      'positionData': positionData.isNotEmpty ? positionData.toString() : '{}',
    };
  }

  ReadingProgress copyWith({
    String? bookFileId,
    String? format,
    int? currentPage,
    int? totalPages,
    String? chapterHref,
    String? epubCfi,
    int? audioPositionMs,
    int? audioDurationMs,
    double? progressPercentage,
    Map<String, dynamic>? positionData,
    DateTime? lastOpenedAt,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      bookFileId: bookFileId ?? this.bookFileId,
      format: format ?? this.format,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      chapterHref: chapterHref ?? this.chapterHref,
      epubCfi: epubCfi ?? this.epubCfi,
      audioPositionMs: audioPositionMs ?? this.audioPositionMs,
      audioDurationMs: audioDurationMs ?? this.audioDurationMs,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      positionData: positionData ?? this.positionData,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

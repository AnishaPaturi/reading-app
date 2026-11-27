class AudioTrack {
  final String id;
  final String audiobookId;
  final String filePath;
  final String fileName;
  final int trackOrder;
  final int durationMs;
  final int discNumber;
  final String format;
  final String? chapterTitle;
  final int fileSizeBytes;
  final String? coverUrl;
  final String? author;

  const AudioTrack({
    required this.id,
    String? audiobookId,
    String? bookId,
    String? fileId,
    String? filePath,
    String? fileName,
    String? title,
    this.trackOrder = 0,
    this.durationMs = 0,
    this.discNumber = 1,
    required this.format,
    this.chapterTitle,
    this.fileSizeBytes = 0,
    this.coverUrl,
    this.author,
  })  : audiobookId = audiobookId ?? bookId ?? '',
        filePath = filePath ?? '',
        fileName = fileName ?? title ?? chapterTitle ?? '';

  // Backward compatibility getters
  String get bookId => audiobookId;
  String get fileId => id;
  String get title => chapterTitle ?? fileName;

  AudioTrack copyWith({
    String? id,
    String? audiobookId,
    String? bookId,
    String? filePath,
    String? fileName,
    String? title,
    int? trackOrder,
    int? durationMs,
    int? discNumber,
    String? format,
    String? chapterTitle,
    int? fileSizeBytes,
    String? coverUrl,
    String? author,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      audiobookId: audiobookId ?? bookId ?? this.audiobookId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? title ?? this.fileName,
      trackOrder: trackOrder ?? this.trackOrder,
      durationMs: durationMs ?? this.durationMs,
      discNumber: discNumber ?? this.discNumber,
      format: format ?? this.format,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      coverUrl: coverUrl ?? this.coverUrl,
      author: author ?? this.author,
    );
  }

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    final trackId = (json['id'] ?? json['fileId'] ?? '') as String;
    final parentId = (json['audiobookId'] ?? json['bookId'] ?? '') as String;
    final name = (json['fileName'] ?? json['title'] ?? 'Audio Track') as String;
    return AudioTrack(
      id: trackId,
      audiobookId: parentId,
      filePath: (json['filePath'] ?? json['path'] ?? '') as String,
      fileName: name,
      trackOrder: (json['trackOrder'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      discNumber: (json['discNumber'] as num?)?.toInt() ?? 1,
      format: (json['format'] ?? json['fileFormat'] ?? 'MP3') as String,
      chapterTitle: json['chapterTitle'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      coverUrl: json['coverUrl'] as String?,
      author: json['author'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'audiobookId': audiobookId,
      'bookId': audiobookId,
      'fileId': id,
      'filePath': filePath,
      'fileName': fileName,
      'title': title,
      'trackOrder': trackOrder,
      'durationMs': durationMs,
      'discNumber': discNumber,
      'format': format,
      'fileFormat': format,
      if (chapterTitle != null) 'chapterTitle': chapterTitle,
      'fileSizeBytes': fileSizeBytes,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (author != null) 'author': author,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioTrack &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

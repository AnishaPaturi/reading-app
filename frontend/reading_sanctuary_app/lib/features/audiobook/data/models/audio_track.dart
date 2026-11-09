class AudioTrack {
  final String id;
  final String bookId;
  final String fileId;
  final String title;
  final String format;
  final int fileSizeBytes;
  final String? coverUrl;
  final String? author;

  const AudioTrack({
    required this.id,
    required this.bookId,
    required this.fileId,
    required this.title,
    required this.format,
    required this.fileSizeBytes,
    this.coverUrl,
    this.author,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: (json['id'] ?? json['fileId'] ?? '') as String,
      bookId: (json['bookId'] ?? '') as String,
      fileId: (json['fileId'] ?? json['id'] ?? '') as String,
      title: (json['fileName'] ?? json['title'] ?? 'Audio Track') as String,
      format: (json['fileFormat'] ?? json['format'] ?? 'MP3') as String,
      fileSizeBytes: (json['fileSizeBytes'] ?? 0) as int,
      coverUrl: json['coverUrl'] as String?,
      author: json['author'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'fileId': fileId,
      'fileName': title,
      'fileFormat': format,
      'fileSizeBytes': fileSizeBytes,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (author != null) 'author': author,
    };
  }
}

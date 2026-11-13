class BookMetadata {
  final String? uploadId;
  final String? fileName;
  final String? format;
  final String? title;
  final String? author;
  final String? genre;
  final String? description;
  final String? isbn;
  final int? pages;
  final int? durationSeconds;
  final String? language;
  final String? coverBase64;

  const BookMetadata({
    this.uploadId,
    this.fileName,
    this.format,
    this.title,
    this.author,
    this.genre,
    this.description,
    this.isbn,
    this.pages,
    this.durationSeconds,
    this.language,
    this.coverBase64,
  });

  Map<String, dynamic> toJson() => {
        'uploadId': uploadId,
        'fileName': fileName,
        'format': format,
        'title': title,
        'author': author,
        'genre': genre,
        'description': description,
        'isbn': isbn,
        'pages': pages,
        'durationSeconds': durationSeconds,
        'language': language,
        'coverBase64': coverBase64,
      };

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    return BookMetadata(
      uploadId: json['uploadId']?.toString(),
      fileName: json['fileName']?.toString(),
      format: json['format']?.toString(),
      title: json['title']?.toString(),
      author: json['author']?.toString(),
      genre: json['genre']?.toString(),
      description: json['description']?.toString(),
      isbn: json['isbn']?.toString(),
      pages: json['pages'] is num ? (json['pages'] as num).toInt() : null,
      durationSeconds: json['durationSeconds'] is num ? (json['durationSeconds'] as num).toInt() : null,
      language: json['language']?.toString(),
      coverBase64: json['coverBase64']?.toString(),
    );
  }

  BookMetadata copyWith({
    String? uploadId,
    String? fileName,
    String? format,
    String? title,
    String? author,
    String? genre,
    String? description,
    String? isbn,
    int? pages,
    int? durationSeconds,
    String? language,
    String? coverBase64,
  }) {
    return BookMetadata(
      uploadId: uploadId ?? this.uploadId,
      fileName: fileName ?? this.fileName,
      format: format ?? this.format,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      description: description ?? this.description,
      isbn: isbn ?? this.isbn,
      pages: pages ?? this.pages,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      language: language ?? this.language,
      coverBase64: coverBase64 ?? this.coverBase64,
    );
  }
}

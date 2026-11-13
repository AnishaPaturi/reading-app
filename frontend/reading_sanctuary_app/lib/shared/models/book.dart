import 'package:flutter/material.dart';

enum ReadingStatus { currentlyReading, wantToRead, toRead, completed, onHold, dnf }

extension ReadingStatusX on ReadingStatus {
  String get label => switch (this) {
        ReadingStatus.currentlyReading => 'Currently Reading',
        ReadingStatus.wantToRead => 'Want to Read',
        ReadingStatus.toRead => 'Want to Read',
        ReadingStatus.completed => 'Completed',
        ReadingStatus.onHold => 'On Hold',
        ReadingStatus.dnf => 'DNF',
      };
}

enum BookFormat { ebook, audiobook }

enum BookFileFormat {
  pdf,
  epub,
  mp3,
  m4b,
}

extension BookFileFormatX on BookFileFormat {
  String get extensionName => switch (this) {
        BookFileFormat.pdf => 'pdf',
        BookFileFormat.epub => 'epub',
        BookFileFormat.mp3 => 'mp3',
        BookFileFormat.m4b => 'm4b',
      };

  String get label => switch (this) {
        BookFileFormat.pdf => 'PDF',
        BookFileFormat.epub => 'EPUB',
        BookFileFormat.mp3 => 'MP3',
        BookFileFormat.m4b => 'M4B',
      };

  bool get isAudio => this == BookFileFormat.mp3 || this == BookFileFormat.m4b;
}

class BookFile {
  final String id;
  final BookFileFormat format;
  final String fileName;
  final int fileSize;
  final String? storageKey;
  final int? durationSeconds;

  const BookFile({
    required this.id,
    required this.format,
    required this.fileName,
    required this.fileSize,
    this.storageKey,
    this.durationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'format': format.name,
        'fileName': fileName,
        'fileSize': fileSize,
        'storageKey': storageKey,
        'durationSeconds': durationSeconds,
      };

  factory BookFile.fromJson(Map<String, dynamic> json) {
    BookFileFormat parseFormat(dynamic val) {
      if (val == null) return BookFileFormat.epub;
      final str = val.toString().toLowerCase();
      if (str.contains('pdf')) return BookFileFormat.pdf;
      if (str.contains('epub')) return BookFileFormat.epub;
      if (str.contains('mp3')) return BookFileFormat.mp3;
      if (str.contains('m4b')) return BookFileFormat.m4b;
      return BookFileFormat.epub;
    }

    return BookFile(
      id: json['id']?.toString() ?? '',
      format: parseFormat(json['format'] ?? json['fileFormat']),
      fileName: json['fileName']?.toString() ?? json['filename']?.toString() ?? 'untitled',
      fileSize: (json['fileSize'] ?? json['fileSizeBytes'] ?? 0) is num
          ? ((json['fileSize'] ?? json['fileSizeBytes'] ?? 0) as num).toInt()
          : 0,
      storageKey: json['storageKey']?.toString(),
      durationSeconds: json['durationSeconds'] is num ? (json['durationSeconds'] as num).toInt() : null,
    );
  }

  BookFile copyWith({
    String? id,
    BookFileFormat? format,
    String? fileName,
    int? fileSize,
    String? storageKey,
    int? durationSeconds,
  }) {
    return BookFile(
      id: id ?? this.id,
      format: format ?? this.format,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      storageKey: storageKey ?? this.storageKey,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.description,
    required this.status,
    required this.progress,
    required this.pages,
    required this.formats,
    required this.addedAt,
    required this.coverColors,
    this.files = const [],
    this.rating,
    this.lastOpenedAt,
    this.tropes = const [],
    this.series,
    this.avgRating,
  });

  final String id;
  final String title;
  final String author;
  final String genre;
  final String description;
  final ReadingStatus status;
  final double progress; // 0..1
  final int pages;
  final List<BookFormat> formats; // one record, many formats (ebook/audiobook)
  final List<BookFile> files; // attached physical files (pdf, epub, mp3, m4b)
  final DateTime addedAt;
  final DateTime? lastOpenedAt;
  final double? rating;
  final List<Color> coverColors;
  final List<String> tropes;
  final String? series;
  final double? avgRating; // community rating (sample data for now)

  int get currentPage => (pages * progress).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'genre': genre,
        'description': description,
        'status': status.name,
        'progress': progress,
        'pages': pages,
        'formats': formats.map((f) => f.name).toList(),
        'files': files.map((f) => f.toJson()).toList(),
        'addedAt': addedAt.toIso8601String(),
        'lastOpenedAt': lastOpenedAt?.toIso8601String(),
        'rating': rating,
        'coverColors': coverColors.map((c) => c.value).toList(),
        'tropes': tropes,
        'series': series,
        'avgRating': avgRating,
      };

  factory Book.fromJson(Map<String, dynamic> json) {
    ReadingStatus parseStatus(dynamic val) {
      if (val == null) return ReadingStatus.wantToRead;
      final str = val.toString().toLowerCase();
      if (str.contains('currently') || str.contains('reading')) return ReadingStatus.currentlyReading;
      if (str.contains('completed')) return ReadingStatus.completed;
      if (str.contains('hold')) return ReadingStatus.onHold;
      if (str.contains('dnf')) return ReadingStatus.dnf;
      return ReadingStatus.wantToRead;
    }

    List<BookFormat> parseFormats(dynamic val) {
      if (val is List && val.isNotEmpty) {
        return val
            .map((f) => f.toString().toLowerCase().contains('audio') ? BookFormat.audiobook : BookFormat.ebook)
            .toList();
      }
      return const [BookFormat.ebook];
    }

    List<BookFile> parseFiles(dynamic val) {
      if (val is List && val.isNotEmpty) {
        return val
            .whereType<Map<String, dynamic>>()
            .map((f) => BookFile.fromJson(f))
            .toList();
      }
      return const [];
    }

    List<Color> parseColors(dynamic val) {
      if (val is List && val.isNotEmpty) {
        return val.map((c) => Color(int.tryParse(c.toString()) ?? 0xFF9482E6)).toList();
      }
      return const [Color(0xFF6B4A5E), Color(0xFF2A1A26)];
    }

    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      author: json['author']?.toString() ?? 'Unknown Author',
      genre: json['genre']?.toString() ?? 'Fiction',
      description: json['description']?.toString() ?? '',
      status: parseStatus(json['status'] ?? json['readingStatus']),
      progress: (json['progress'] is num
              ? (json['progress'] as num).toDouble()
              : (json['progressPercentage'] is num ? ((json['progressPercentage'] as num) / 100.0) : 0.0))
          .clamp(0.0, 1.0),
      pages: (json['pages'] ?? json['totalPages'] ?? 250) is num
          ? ((json['pages'] ?? json['totalPages'] ?? 250) as num).toInt()
          : 250,
      formats: parseFormats(json['formats']),
      files: parseFiles(json['files']),
      addedAt: json['addedAt'] != null
          ? DateTime.tryParse(json['addedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastOpenedAt: json['lastOpenedAt'] != null ? DateTime.tryParse(json['lastOpenedAt'].toString()) : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      coverColors: parseColors(json['coverColors']),
      tropes: json['tropes'] is List ? (json['tropes'] as List).map((t) => t.toString()).toList() : const [],
      series: json['series']?.toString(),
      avgRating: json['avgRating'] != null ? (json['avgRating'] as num).toDouble() : null,
    );
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? genre,
    String? description,
    ReadingStatus? status,
    double? progress,
    int? pages,
    List<BookFormat>? formats,
    List<BookFile>? files,
    DateTime? addedAt,
    DateTime? lastOpenedAt,
    double? rating,
    List<Color>? coverColors,
    List<String>? tropes,
    String? series,
    double? avgRating,
  }) =>
      Book(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        genre: genre ?? this.genre,
        description: description ?? this.description,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        pages: pages ?? this.pages,
        formats: formats ?? this.formats,
        files: files ?? this.files,
        addedAt: addedAt ?? this.addedAt,
        coverColors: coverColors ?? this.coverColors,
        rating: rating ?? this.rating,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
        tropes: tropes ?? this.tropes,
        series: series ?? this.series,
        avgRating: avgRating ?? this.avgRating,
      );
}

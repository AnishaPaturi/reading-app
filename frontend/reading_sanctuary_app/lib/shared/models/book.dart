import 'package:flutter/material.dart';

enum ReadingStatus { currentlyReading, wantToRead, toRead, completed, onHold, dnf, deleted }

extension ReadingStatusX on ReadingStatus {
  String get label => switch (this) {
        ReadingStatus.currentlyReading => 'Currently Reading',
        ReadingStatus.wantToRead => 'Want to Read',
        ReadingStatus.toRead => 'Want to Read',
        ReadingStatus.completed => 'Completed',
        ReadingStatus.onHold => 'On Hold',
        ReadingStatus.dnf => 'Did Not Finish',
        ReadingStatus.deleted => 'Deleted',
      };

  String get shortLabel => switch (this) {
        ReadingStatus.currentlyReading => 'Reading',
        ReadingStatus.wantToRead => 'TBR',
        ReadingStatus.toRead => 'TBR',
        ReadingStatus.completed => 'Completed',
        ReadingStatus.onHold => 'Paused',
        ReadingStatus.dnf => 'DNF',
        ReadingStatus.deleted => 'Deleted',
      };
}

enum BookFormat { ebook, audiobook }

enum BookFileFormat {
  pdf,
  epub,
  mp3,
  m4b,
  m4a,
}

extension BookFileFormatX on BookFileFormat {
  String get extensionName => switch (this) {
        BookFileFormat.pdf => 'pdf',
        BookFileFormat.epub => 'epub',
        BookFileFormat.mp3 => 'mp3',
        BookFileFormat.m4b => 'm4b',
        BookFileFormat.m4a => 'm4a',
      };

  String get label => switch (this) {
        BookFileFormat.pdf => 'PDF',
        BookFileFormat.epub => 'EPUB',
        BookFileFormat.mp3 => 'MP3',
        BookFileFormat.m4b => 'M4B',
        BookFileFormat.m4a => 'M4A',
      };

  bool get isAudio => this == BookFileFormat.mp3 || this == BookFileFormat.m4b || this == BookFileFormat.m4a;
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
      if (str.contains('m4a')) return BookFileFormat.m4a;
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
    this.coverImageUrl,
    this.hasCover = false,
    this.coverUpdatedAt,
    this.dnfDate,
    this.dnfReason,
    this.dnfNotes,
    this.previousStatus,
    this.deletedAt,
    this.ratingOutOf100,
    this.spiceRating,
    this.mood,
    this.recommendation,
    this.purchasePrice,
    this.currency,
    this.acquisitionMethod,
    this.purchaseDate,
    this.startDate,
    this.completionDate,
    this.publisher,
    this.isbn,
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
  final String? coverImageUrl;
  final bool hasCover;
  final DateTime? coverUpdatedAt;
  final DateTime? dnfDate;
  final String? dnfReason;
  final String? dnfNotes;
  final ReadingStatus? previousStatus;
  final DateTime? deletedAt;

  // Additional metadata fields (Features.md Module 7 & Table 2.1)
  final int? ratingOutOf100;
  final int? spiceRating;
  final String? mood;
  final String? recommendation;
  final double? purchasePrice;
  final String? currency;
  final String? acquisitionMethod;
  final DateTime? purchaseDate;
  final DateTime? startDate;
  final DateTime? completionDate;
  final String? publisher;
  final String? isbn;

  String? get effectiveCoverUrl {
    // If book explicitly has no cover and no cover URL provided, return null for styled fallback
    if (!hasCover && (coverImageUrl == null || coverImageUrl!.trim().isEmpty)) {
      return null;
    }

    String? url = coverImageUrl;
    if ((url == null || url.trim().isEmpty) && hasCover && id.isNotEmpty) {
      url = '/api/v1/books/$id/cover';
    }

    if (url != null && url.trim().isNotEmpty) {
      final trimmed = url.trim();
      if (trimmed.startsWith('data:')) {
        return trimmed;
      }
      if (coverUpdatedAt != null) {
        final separator = trimmed.contains('?') ? '&' : '?';
        return '$trimmed${separator}v=${coverUpdatedAt!.millisecondsSinceEpoch}';
      }
      return trimmed;
    }

    return null;
  }

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
        'coverColors': coverColors.map((c) => c.toARGB32()).toList(),
        'tropes': tropes,
        'series': series,
        'avgRating': avgRating,
        if (coverImageUrl != null) 'coverImageUrl': coverImageUrl,
        'hasCover': hasCover,
        if (coverUpdatedAt != null) 'coverUpdatedAt': coverUpdatedAt!.toIso8601String(),
        if (dnfDate != null) 'dnfDate': dnfDate!.toIso8601String(),
        if (dnfReason != null) 'dnfReason': dnfReason,
        if (dnfNotes != null) 'dnfNotes': dnfNotes,
        if (previousStatus != null) 'previousStatus': previousStatus!.name,
        if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
        if (ratingOutOf100 != null) 'ratingOutOf100': ratingOutOf100,
        if (spiceRating != null) 'spiceRating': spiceRating,
        if (mood != null) 'mood': mood,
        if (recommendation != null) 'recommendation': recommendation,
        if (purchasePrice != null) 'purchasePrice': purchasePrice,
        if (currency != null) 'currency': currency,
        if (acquisitionMethod != null) 'acquisitionMethod': acquisitionMethod,
        if (purchaseDate != null) 'purchaseDate': purchaseDate!.toIso8601String(),
        if (startDate != null) 'startDate': startDate!.toIso8601String(),
        if (completionDate != null) 'completionDate': completionDate!.toIso8601String(),
        if (publisher != null) 'publisher': publisher,
        if (isbn != null) 'isbn': isbn,
      };

  factory Book.fromJson(Map<String, dynamic> json) {
    ReadingStatus parseStatus(dynamic val) {
      if (val == null) return ReadingStatus.wantToRead;
      final str = val.toString().toLowerCase();
      if (str.contains('delete')) return ReadingStatus.deleted;
      if (str.contains('currently') || str.contains('reading')) return ReadingStatus.currentlyReading;
      if (str.contains('completed')) return ReadingStatus.completed;
      if (str.contains('hold')) return ReadingStatus.onHold;
      if (str.contains('dnf')) return ReadingStatus.dnf;
      return ReadingStatus.wantToRead;
    }

    ReadingStatus? parseNullableStatus(dynamic val) {
      if (val == null) return null;
      return parseStatus(val);
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

    List<String> parseTropes(dynamic val) {
      if (val is List) {
        return val.map((t) => t.toString()).toList();
      }
      if (val is String && val.trim().isNotEmpty) {
        return val.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      }
      return const [];
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str);
    }

    final bool hasCover = json['hasCover'] == true ||
        (json['coverStorageKey'] != null && json['coverStorageKey'].toString().isNotEmpty) ||
        (json['coverUrl'] != null && json['coverUrl'].toString().trim().isNotEmpty);

    final DateTime? coverUpdatedAt = json['coverUpdatedAt'] != null
        ? DateTime.tryParse(json['coverUpdatedAt'].toString())
        : (json['cover_updated_at'] != null ? DateTime.tryParse(json['cover_updated_at'].toString()) : null);

    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled',
      author: json['author']?.toString() ?? json['publisher']?.toString() ?? 'Unknown Author',
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
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now()),
      lastOpenedAt: json['lastOpenedAt'] != null ? DateTime.tryParse(json['lastOpenedAt'].toString()) : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      coverColors: parseColors(json['coverColors']),
      tropes: parseTropes(json['tropes']),
      series: json['series']?.toString(),
      avgRating: json['avgRating'] != null ? (json['avgRating'] as num).toDouble() : null,
      hasCover: hasCover,
      coverUpdatedAt: coverUpdatedAt,
      coverImageUrl: json['coverUrl']?.toString() ??
          json['coverImageUrl']?.toString() ??
          json['cover_image_url']?.toString() ??
          (hasCover ? '/api/v1/books/${json['id']}/cover' : null),
      dnfDate: json['dnfDate'] != null
          ? DateTime.tryParse(json['dnfDate'].toString())
          : (json['dnfAt'] != null ? DateTime.tryParse(json['dnfAt'].toString()) : null),
      dnfReason: json['dnfReason']?.toString(),
      dnfNotes: json['dnfNotes']?.toString(),
      previousStatus: parseNullableStatus(json['previousStatus'] ?? json['previousReadingStatus']),
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt'].toString()) : null,
      ratingOutOf100: json['ratingOutOf100'] is num ? (json['ratingOutOf100'] as num).toInt() : null,
      spiceRating: json['spiceRating'] is num ? (json['spiceRating'] as num).toInt() : null,
      mood: json['mood']?.toString(),
      recommendation: json['recommendation']?.toString(),
      purchasePrice: json['purchasePrice'] is num ? (json['purchasePrice'] as num).toDouble() : null,
      currency: json['currency']?.toString() ?? 'INR',
      acquisitionMethod: json['acquisitionMethod']?.toString(),
      purchaseDate: parseDate(json['purchaseDate']),
      startDate: parseDate(json['startDate'] ?? json['startedAt']),
      completionDate: parseDate(json['completionDate'] ?? json['completedAt']),
      publisher: json['publisher']?.toString(),
      isbn: json['isbn']?.toString(),
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
    String? coverImageUrl,
    bool? hasCover,
    DateTime? coverUpdatedAt,
    DateTime? dnfDate,
    String? dnfReason,
    String? dnfNotes,
    bool clearDnf = false,
    ReadingStatus? previousStatus,
    DateTime? deletedAt,
    bool clearDeletedMetadata = false,
    int? ratingOutOf100,
    int? spiceRating,
    String? mood,
    String? recommendation,
    double? purchasePrice,
    String? currency,
    String? acquisitionMethod,
    DateTime? purchaseDate,
    DateTime? startDate,
    DateTime? completionDate,
    String? publisher,
    String? isbn,
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
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        hasCover: hasCover ?? this.hasCover,
        coverUpdatedAt: coverUpdatedAt ?? this.coverUpdatedAt,
        dnfDate: clearDnf ? null : (dnfDate ?? this.dnfDate),
        dnfReason: clearDnf ? null : (dnfReason ?? this.dnfReason),
        dnfNotes: clearDnf ? null : (dnfNotes ?? this.dnfNotes),
        previousStatus: clearDeletedMetadata ? null : (previousStatus ?? this.previousStatus),
        deletedAt: clearDeletedMetadata ? null : (deletedAt ?? this.deletedAt),
        ratingOutOf100: ratingOutOf100 ?? this.ratingOutOf100,
        spiceRating: spiceRating ?? this.spiceRating,
        mood: mood ?? this.mood,
        recommendation: recommendation ?? this.recommendation,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        currency: currency ?? this.currency,
        acquisitionMethod: acquisitionMethod ?? this.acquisitionMethod,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        startDate: startDate ?? this.startDate,
        completionDate: completionDate ?? this.completionDate,
        publisher: publisher ?? this.publisher,
        isbn: isbn ?? this.isbn,
      );
}

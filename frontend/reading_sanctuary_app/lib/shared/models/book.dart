import 'package:flutter/material.dart';

enum ReadingStatus { currentlyReading, wantToRead, completed, onHold, dnf }

extension ReadingStatusX on ReadingStatus {
  String get label => switch (this) {
        ReadingStatus.currentlyReading => 'Currently Reading',
        ReadingStatus.wantToRead => 'Want to Read',
        ReadingStatus.completed => 'Completed',
        ReadingStatus.onHold => 'On Hold',
        ReadingStatus.dnf => 'DNF',
      };
}

enum BookFormat { ebook, audiobook }

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
  final List<BookFormat> formats; // one record, many formats
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

  Book copyWith({ReadingStatus? status, double? progress, DateTime? lastOpenedAt, DateTime? addedAt}) => Book(
        id: id,
        title: title,
        author: author,
        genre: genre,
        description: description,
        status: status ?? this.status,
        progress: progress ?? this.progress,
        pages: pages,
        formats: formats,
        addedAt: addedAt ?? this.addedAt,
        coverColors: coverColors,
        rating: rating,
        lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
        tropes: tropes,
        series: series,
        avgRating: avgRating,
      );
}

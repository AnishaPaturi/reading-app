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

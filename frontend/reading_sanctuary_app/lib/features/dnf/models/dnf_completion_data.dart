import 'package:flutter/material.dart';
import '../../../shared/models/book.dart';

class DnfCompletionData {
  final String bookId;
  final String title;
  final String author;
  final String? coverImageUrl;
  final List<Color> coverColors;
  final double readingProgress;
  final int currentPage;
  final int totalPages;
  final DateTime dnfDate;
  final String? dnfReason;
  final String? dnfNotes;
  final ReadingStatus previousStatus;
  final Book book;

  const DnfCompletionData({
    required this.bookId,
    required this.title,
    required this.author,
    this.coverImageUrl,
    this.coverColors = const [Color(0xFF2B3A55), Color(0xFF111A2B)],
    required this.readingProgress,
    required this.currentPage,
    required this.totalPages,
    required this.dnfDate,
    this.dnfReason,
    this.dnfNotes,
    this.previousStatus = ReadingStatus.currentlyReading,
    required this.book,
  });

  factory DnfCompletionData.fromBook(Book book, {String? reason, String? notes}) {
    return DnfCompletionData(
      bookId: book.id,
      title: book.title,
      author: book.author,
      coverImageUrl: book.effectiveCoverUrl,
      coverColors: book.coverColors,
      readingProgress: book.progress,
      currentPage: book.currentPage,
      totalPages: book.pages,
      dnfDate: book.dnfDate ?? DateTime.now(),
      dnfReason: reason ?? book.dnfReason,
      dnfNotes: notes ?? book.dnfNotes,
      previousStatus: book.status == ReadingStatus.dnf ? ReadingStatus.currentlyReading : book.status,
      book: book,
    );
  }

  DnfCompletionData copyWith({
    String? dnfReason,
    String? dnfNotes,
    DateTime? dnfDate,
  }) {
    return DnfCompletionData(
      bookId: bookId,
      title: title,
      author: author,
      coverImageUrl: coverImageUrl,
      coverColors: coverColors,
      readingProgress: readingProgress,
      currentPage: currentPage,
      totalPages: totalPages,
      dnfDate: dnfDate ?? this.dnfDate,
      dnfReason: dnfReason ?? this.dnfReason,
      dnfNotes: dnfNotes ?? this.dnfNotes,
      previousStatus: previousStatus,
      book: book,
    );
  }
}

import 'package:flutter/material.dart';
import '../models/book.dart';

/// Screens depend on this interface only. Swap MockBookRepository for an
/// HTTP-backed implementation (Spring Boot) without touching the UI.
abstract class BookRepository {
  Future<List<Book>> getBooks();
  Future<void> updateStatus(String id, ReadingStatus status);
  Future<void> updateProgress(String id, double progress);
  Future<void> addBook(Book book);
}

class MockBookRepository implements BookRepository {
  MockBookRepository([List<Book>? books]) : _books = books ?? sample();
  List<Book> _books;

  @override
  Future<List<Book>> getBooks() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_books);
  }

  @override
  Future<void> updateStatus(String id, ReadingStatus status) async {
    _books = [
      for (final b in _books)
        if (b.id == id)
          b.copyWith(
            status: status,
            progress: status == ReadingStatus.completed ? 1.0 : b.progress,
          )
        else
          b
    ];
  }

  @override
  Future<void> addBook(Book book) async {
    if (_books.any((b) => b.id == book.id)) return; // never duplicate a record
    _books = [..._books, book.copyWith(status: ReadingStatus.wantToRead, addedAt: DateTime.now())];
  }

  @override
  Future<void> updateProgress(String id, double progress) async {
    final p = progress.clamp(0.0, 1.0).toDouble();
    _books = [
      for (final b in _books)
        if (b.id == id)
          b.copyWith(
            progress: p,
            lastOpenedAt: DateTime.now(),
            status: b.status == ReadingStatus.wantToRead && p > 0
                ? ReadingStatus.currentlyReading
                : b.status,
          )
        else
          b
    ];
  }

  static List<Book> sample() {
    final now = DateTime.now();
    Book b(String id, String t, String a, String g, ReadingStatus s, double p, int pages,
            List<BookFormat> f, int addedDays, int? openedDays, double? r, int c1, int c2,
            String d) =>
        Book(
          id: id, title: t, author: a, genre: g, status: s, progress: p, pages: pages,
          formats: f, description: d, rating: r,
          addedAt: now.subtract(Duration(days: addedDays)),
          lastOpenedAt: openedDays == null ? null : now.subtract(Duration(days: openedDays)),
          coverColors: [Color(c1), Color(c2)],
        );
    const e = [BookFormat.ebook];
    const ea = [BookFormat.ebook, BookFormat.audiobook];
    const reading = ReadingStatus.currentlyReading;
    const want = ReadingStatus.wantToRead;
    const done = ReadingStatus.completed;
    const hold = ReadingStatus.onHold;
    const dnf = ReadingStatus.dnf;
    return [
      b('b1', 'The Silent Patient', 'Alex Michaelides', 'Thriller', reading, .42, 336, ea, 20, 1, null, 0xFF2B3A55, 0xFF111A2B, 'A psychological thriller about a woman who stops speaking.'),
      b('b2', 'The Seven Husbands of Evelyn Hugo', 'Taylor Jenkins Reid', 'Historical Fiction', reading, .68, 400, e, 35, 3, null, 0xFF7A2E3B, 0xFF3A1219, 'A reclusive screen icon finally tells her story.'),
      b('b3', 'Atomic Habits', 'James Clear', 'Self-Help', done, 1, 320, ea, 90, 40, 4.5, 0xFFB5651D, 0xFF5E3210, 'A practical framework for building better habits.'),
      b('b4', 'The Midnight Library', 'Matt Haig', 'Fantasy', want, 0, 304, e, 5, null, null, 0xFF1F3B4D, 0xFF0B1A24, 'A library between life and death holds every possible life.'),
      b('b5', 'It Ends with Us', 'Colleen Hoover', 'Romance', hold, .3, 384, e, 60, 25, null, 0xFF8C6A5A, 0xFF402E27, 'A contemporary love story with difficult choices.'),
      b('b6', 'The Book Thief', 'Markus Zusak', 'Historical Fiction', done, 1, 552, e, 150, 70, 5, 0xFF4A4A44, 0xFF1C1C19, 'A young girl steals books in wartime Germany.'),
      b('b7', "A Good Girl's Guide to Murder", 'Holly Jackson', 'Mystery', want, 0, 448, e, 3, null, null, 0xFF5B2A5E, 0xFF22102A, 'A student investigates a closed murder case.'),
      b('b8', 'The Psychology of Money', 'Morgan Housel', 'Finance', reading, .15, 256, ea, 12, 0, null, 0xFF2F5D50, 0xFF12302A, 'Short essays on how people think about money.'),
      b('b9', 'The Song of Achilles', 'Madeline Miller', 'Mythology', done, 1, 378, ea, 200, 100, 5, 0xFF9C7B3C, 0xFF45331A, 'The Iliad retold through Patroclus.'),
      b('b10', 'The Alchemist', 'Paulo Coelho', 'Fiction', dnf, .22, 208, e, 80, 55, 2.5, 0xFFB08A3E, 0xFF5A3F14, 'A shepherd travels in search of treasure.'),
      b('b11', 'The Inheritance Games', 'Jennifer Lynn Barnes', 'Mystery', want, 0, 384, e, 2, null, null, 0xFF1E1E2E, 0xFF0A0A14, 'A teenager inherits a fortune and a puzzle.'),
      b('b12', 'The Great Gatsby', 'F. Scott Fitzgerald', 'Classics', done, 1, 180, e, 300, 120, 4, 0xFF2E6F6A, 0xFF123532, 'A portrait of ambition in the Jazz Age.'),
    ];
  }
}

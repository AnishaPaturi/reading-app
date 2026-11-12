import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/book.dart';
import 'book_repository.dart';

class HttpBookRepository implements BookRepository {
  final ApiClient _apiClient;
  static const String _storageKey = 'sanctuary_dynamic_books';

  HttpBookRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<List<Book>> getBooks() async {
    List<Book> cachedBooks = await _loadFromCache();

    try {
      final response = await _apiClient.get('/books');
      if (response is List) {
        final serverBooks = <Book>[];
        for (final item in response) {
          if (item is Map<String, dynamic>) {
            final bookId = item['id']?.toString() ?? '';
            ReadingStatus status = ReadingStatus.wantToRead;
            double progress = 0.0;
            int totalPages = 250;
            int currentPage = 0;

            try {
              final readingRes = await _apiClient.get('/books/$bookId/reading');
              if (readingRes is Map<String, dynamic>) {
                final statusStr = readingRes['status']?.toString();
                if (statusStr != null) {
                  status = _mapReadingStatus(statusStr);
                }
                if (readingRes['progressPercentage'] is num) {
                  progress = ((readingRes['progressPercentage'] as num) / 100.0).clamp(0.0, 1.0);
                }
                if (readingRes['totalPages'] is int) {
                  totalPages = readingRes['totalPages'] as int;
                }
                if (readingRes['currentPage'] is int) {
                  currentPage = readingRes['currentPage'] as int;
                }
              }
            } catch (_) {}

            final colorList = _generateCoverColors(bookId);
            serverBooks.add(Book(
              id: bookId,
              title: item['title']?.toString() ?? 'Untitled',
              author: item['publisher']?.toString() ?? 'Community Author',
              genre: item['language']?.toString() ?? 'Fiction',
              description: item['description']?.toString() ?? '',
              status: status,
              progress: progress > 0 ? progress : (currentPage > 0 ? (currentPage / totalPages) : 0.0),
              pages: totalPages,
              formats: const [BookFormat.ebook, BookFormat.audiobook],
              addedAt: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
              coverColors: colorList,
            ));
          }
        }

        if (serverBooks.isNotEmpty) {
          // Merge server books with any locally created books that haven't synced
          final mergedMap = <String, Book>{};
          for (final b in cachedBooks) {
            mergedMap[b.id] = b;
          }
          for (final b in serverBooks) {
            mergedMap[b.id] = b;
          }
          final mergedList = mergedMap.values.toList();
          await _saveToCache(mergedList);
          return mergedList;
        }
      }
    } catch (_) {
      // Offline fallback: continue to return cached books
    }

    if (cachedBooks.isEmpty) {
      cachedBooks = _initialDynamicLibrary();
      await _saveToCache(cachedBooks);
    }

    return cachedBooks;
  }

  @override
  Future<void> updateStatus(String id, ReadingStatus status) async {
    final books = await _loadFromCache();
    final updated = [
      for (final b in books)
        if (b.id == id)
          b.copyWith(
            status: status,
            progress: status == ReadingStatus.completed ? 1.0 : b.progress,
            lastOpenedAt: DateTime.now(),
          )
        else
          b
    ];
    await _saveToCache(updated);

    try {
      await _apiClient.patch('/books/$id/reading', body: {
        'status': _statusToBackend(status),
      });
    } catch (_) {}
  }

  @override
  Future<void> updateProgress(String id, double progress) async {
    final p = progress.clamp(0.0, 1.0).toDouble();
    final books = await _loadFromCache();
    final updated = [
      for (final b in books)
        if (b.id == id)
          b.copyWith(
            progress: p,
            lastOpenedAt: DateTime.now(),
            status: b.status == ReadingStatus.wantToRead && p > 0
                ? ReadingStatus.currentlyReading
                : (p >= 1.0 ? ReadingStatus.completed : b.status),
          )
        else
          b
    ];
    await _saveToCache(updated);

    try {
      final currentBook = updated.firstWhere((b) => b.id == id);
      await _apiClient.patch('/books/$id/reading', body: {
        'currentPage': currentBook.currentPage,
        'totalPages': currentBook.pages,
        'status': _statusToBackend(currentBook.status),
      });
    } catch (_) {}
  }

  @override
  Future<void> addBook(Book book) async {
    final books = await _loadFromCache();
    final updated = [
      book.copyWith(status: book.status, addedAt: DateTime.now()),
      ...books.where((b) => b.id != book.id),
    ];
    await _saveToCache(updated);

    try {
      final res = await _apiClient.post('/books', body: {
        'title': book.title.trim(),
        'description': book.description.trim(),
        'language': book.genre,
        'publisher': book.author,
      });

      if (res is Map<String, dynamic> && res['id'] != null) {
        final serverId = res['id'].toString();
        await _apiClient.patch('/books/$serverId/reading', body: {
          'status': _statusToBackend(book.status),
          'currentPage': book.currentPage,
          'totalPages': book.pages,
        });
      }
    } catch (_) {}
  }

  Future<List<Book>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          return decoded.map((item) => Book.fromJson(item as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveToCache(List<Book> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = books.map((b) => b.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (_) {}
  }

  static ReadingStatus _mapReadingStatus(String status) {
    switch (status.toUpperCase()) {
      case 'CURRENTLY_READING':
        return ReadingStatus.currentlyReading;
      case 'COMPLETED':
        return ReadingStatus.completed;
      case 'ON_HOLD':
        return ReadingStatus.onHold;
      case 'DNF':
        return ReadingStatus.dnf;
      case 'WANT_TO_READ':
      default:
        return ReadingStatus.wantToRead;
    }
  }

  static String _statusToBackend(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.currentlyReading:
        return 'CURRENTLY_READING';
      case ReadingStatus.completed:
        return 'COMPLETED';
      case ReadingStatus.onHold:
        return 'ON_HOLD';
      case ReadingStatus.dnf:
        return 'DNF';
      case ReadingStatus.wantToRead:
        return 'WANT_TO_READ';
    }
  }

  static List<Color> _generateCoverColors(String seed) {
    final hash = seed.hashCode.abs();
    final palettes = [
      [const Color(0xFF2B3A55), const Color(0xFF111A2B)],
      [const Color(0xFF7A2E3B), const Color(0xFF3A1219)],
      [const Color(0xFFB5651D), const Color(0xFF5E3210)],
      [const Color(0xFF1F3B4D), const Color(0xFF0B1A24)],
      [const Color(0xFF8C6A5A), const Color(0xFF402E27)],
      [const Color(0xFF2F5D50), const Color(0xFF12302A)],
      [const Color(0xFF5B2A5E), const Color(0xFF22102A)],
    ];
    return palettes[hash % palettes.length];
  }

  static List<Book> _initialDynamicLibrary() {
    final now = DateTime.now();
    return [
      Book(
        id: 'book-1',
        title: 'The Silent Patient',
        author: 'Alex Michaelides',
        genre: 'Thriller',
        status: ReadingStatus.currentlyReading,
        progress: 0.42,
        pages: 336,
        formats: const [BookFormat.ebook, BookFormat.audiobook],
        description: 'A shocking psychological thriller of a woman’s act of violence against her husband—and of the therapist obsessed with uncovering her motive.',
        rating: 4.5,
        addedAt: now.subtract(const Duration(days: 14)),
        lastOpenedAt: now.subtract(const Duration(hours: 3)),
        coverColors: const [Color(0xFF2B3A55), Color(0xFF111A2B)],
        tropes: const ['Psychological', 'Plot Twist', 'Unreliable Narrator'],
      ),
      Book(
        id: 'book-2',
        title: 'Atomic Habits',
        author: 'James Clear',
        genre: 'Self-Help',
        status: ReadingStatus.currentlyReading,
        progress: 0.65,
        pages: 320,
        formats: const [BookFormat.ebook, BookFormat.audiobook],
        description: 'An easy & proven way to build good habits & break bad ones with actionable systems and compounding gains.',
        rating: 4.9,
        addedAt: now.subtract(const Duration(days: 30)),
        lastOpenedAt: now.subtract(const Duration(hours: 1)),
        coverColors: const [Color(0xFFB5651D), Color(0xFF5E3210)],
        tropes: const ['Productivity', 'Self Improvement', 'Habits'],
      ),
      Book(
        id: 'book-3',
        title: 'The Midnight Library',
        author: 'Matt Haig',
        genre: 'Fantasy',
        status: ReadingStatus.wantToRead,
        progress: 0.0,
        pages: 304,
        formats: const [BookFormat.ebook],
        description: 'Between life and death there is a library, and within that library, the shelves go on forever. Every book provides a chance to try another life.',
        rating: 4.2,
        addedAt: now.subtract(const Duration(days: 5)),
        coverColors: const [Color(0xFF1F3B4D), Color(0xFF0B1A24)],
        tropes: const ['Magical Realism', 'Second Chances', 'Parallel Lives'],
      ),
      Book(
        id: 'book-4',
        title: 'The Psychology of Money',
        author: 'Morgan Housel',
        genre: 'Finance',
        status: ReadingStatus.completed,
        progress: 1.0,
        pages: 256,
        formats: const [BookFormat.ebook, BookFormat.audiobook],
        description: 'Timeless lessons on wealth, greed, and happiness doing well with money isn’t necessarily about what you know. It’s about how you behave.',
        rating: 4.8,
        addedAt: now.subtract(const Duration(days: 45)),
        lastOpenedAt: now.subtract(const Duration(days: 2)),
        coverColors: const [Color(0xFF2F5D50), Color(0xFF12302A)],
        tropes: const ['Mindset', 'Finance', 'Wisdom'],
      ),
    ];
  }
}

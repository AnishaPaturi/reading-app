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
      final response = await _apiClient.get(
        '/books',
        timeout: const Duration(seconds: 5),
      );
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
              final readingRes = await _apiClient.get(
                '/books/$bookId/reading',
                timeout: const Duration(seconds: 2),
              );
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
            final String? coverUrl = item['coverUrl']?.toString() ??
                item['coverImageUrl']?.toString() ??
                (item['coverStorageKey'] != null ? '/books/$bookId/cover' : null) ??
                (item['hasCover'] == true ? '/books/$bookId/cover' : null);

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
              coverImageUrl: coverUrl,
            ));
          }
        }

        await _saveToCache(serverBooks);
        return serverBooks;
      }
    } catch (_) {
      // Offline fallback: continue to return cached books
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
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 500));
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          final list = decoded.map((item) => Book.fromJson(item as Map<String, dynamic>)).toList();
          // Filter out legacy sample/placeholder books (IDs starting with 'b' like 'b1'..'b12')
          final cleaned = list.where((b) => !RegExp(r'^b\d+$').hasMatch(b.id)).toList();
          if (cleaned.length != list.length) {
            await _saveToCache(cleaned);
          }
          return cleaned;
        }
      }
    } catch (_) {}
    return [];
  }

  Future<void> _saveToCache(List<Book> books) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(const Duration(milliseconds: 100));
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
      case ReadingStatus.toRead:
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
}

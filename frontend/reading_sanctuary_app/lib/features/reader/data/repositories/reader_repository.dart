import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/reader_annotations.dart';
import '../models/reader_position.dart';

abstract class ReaderRepository {
  Future<ReaderPosition?> getPosition({
    required String bookId,
    required String fileId,
  });

  Future<ReaderPosition> savePosition({
    required String bookId,
    required String fileId,
    required ReaderPosition position,
  });

  Future<void> resetPosition({
    required String bookId,
    required String fileId,
  });

  Future<List<ReaderBookmark>> getBookmarks({required String bookId});

  Future<ReaderBookmark> createBookmark({
    required String bookId,
    required String bookFileId,
    required String locationType,
    required String locationValue,
    int? pageNumber,
    String? label,
    String? note,
  });

  Future<void> deleteBookmark({
    required String bookId,
    required String bookmarkId,
  });

  Future<List<ReaderHighlight>> getHighlights({required String bookId});

  Future<ReaderHighlight> createHighlight({
    required String bookId,
    required String bookFileId,
    required String selectedText,
    required String locationType,
    required String startLocation,
    required String endLocation,
    int? pageNumber,
    ReaderHighlightColor color = ReaderHighlightColor.yellow,
    String? annotationNote,
  });

  Future<void> deleteHighlight({
    required String bookId,
    required String highlightId,
  });

  Future<List<ReaderBookNote>> getNotes({required String bookId});

  Future<ReaderBookNote> createNote({
    required String bookId,
    required String title,
    required String content,
  });

  Future<void> deleteNote({
    required String bookId,
    required String noteId,
  });
}

class HttpReaderRepository implements ReaderRepository {
  final String baseUrl;
  final String? Function() tokenProvider;

  HttpReaderRepository({
    String? baseUrl,
    required this.tokenProvider,
  }) : baseUrl = baseUrl ?? _resolveBaseUrl();

  static String _resolveBaseUrl() => ApiConfig.baseUrl;

  Map<String, String> _headers() {
    final token = tokenProvider();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<ReaderPosition?> getPosition({
    required String bookId,
    required String fileId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/books/$bookId/files/$fileId/reading-position'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return ReaderPosition.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching position: $e');
      return null;
    }
  }

  @override
  Future<ReaderPosition> savePosition({
    required String bookId,
    required String fileId,
    required ReaderPosition position,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/books/$bookId/files/$fileId/reading-position'),
      headers: _headers(),
      body: jsonEncode(position.toJson()),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ReaderPosition.fromJson(data);
    }
    throw Exception('Failed to save reading position (HTTP ${res.statusCode})');
  }

  @override
  Future<void> resetPosition({
    required String bookId,
    required String fileId,
  }) async {
    await http.delete(
      Uri.parse('$baseUrl/books/$bookId/files/$fileId/reading-position'),
      headers: _headers(),
    );
  }

  @override
  Future<List<ReaderBookmark>> getBookmarks({required String bookId}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/books/$bookId/bookmarks'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => ReaderBookmark.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ReaderBookmark> createBookmark({
    required String bookId,
    required String bookFileId,
    required String locationType,
    required String locationValue,
    int? pageNumber,
    String? label,
    String? note,
  }) async {
    final body = {
      'bookFileId': bookFileId,
      'locationType': locationType,
      'locationValue': locationValue,
      if (pageNumber != null) 'pageNumber': pageNumber,
      if (label != null) 'label': label,
      if (note != null) 'note': note,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/books/$bookId/bookmarks'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return ReaderBookmark.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create bookmark (HTTP ${res.statusCode})');
  }

  @override
  Future<void> deleteBookmark({required String bookId, required String bookmarkId}) async {
    await http.delete(
      Uri.parse('$baseUrl/books/$bookId/bookmarks/$bookmarkId'),
      headers: _headers(),
    );
  }

  @override
  Future<List<ReaderHighlight>> getHighlights({required String bookId}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/books/$bookId/highlights'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => ReaderHighlight.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ReaderHighlight> createHighlight({
    required String bookId,
    required String bookFileId,
    required String selectedText,
    required String locationType,
    required String startLocation,
    required String endLocation,
    int? pageNumber,
    ReaderHighlightColor color = ReaderHighlightColor.yellow,
    String? annotationNote,
  }) async {
    final body = {
      'bookFileId': bookFileId,
      'selectedText': selectedText,
      'locationType': locationType,
      'startLocation': startLocation,
      'endLocation': endLocation,
      if (pageNumber != null) 'pageNumber': pageNumber,
      'color': color.nameUpper,
      if (annotationNote != null) 'annotationNote': annotationNote,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/books/$bookId/highlights'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return ReaderHighlight.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create highlight (HTTP ${res.statusCode})');
  }

  @override
  Future<void> deleteHighlight({required String bookId, required String highlightId}) async {
    await http.delete(
      Uri.parse('$baseUrl/books/$bookId/highlights/$highlightId'),
      headers: _headers(),
    );
  }

  @override
  Future<List<ReaderBookNote>> getNotes({required String bookId}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/books/$bookId/notes'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return list.map((e) => ReaderBookNote.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<ReaderBookNote> createNote({
    required String bookId,
    required String title,
    required String content,
  }) async {
    final body = {
      'title': title,
      'content': content,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/books/$bookId/notes'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (res.statusCode == 201 || res.statusCode == 200) {
      return ReaderBookNote.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create note (HTTP ${res.statusCode})');
  }

  @override
  Future<void> deleteNote({required String bookId, required String noteId}) async {
    await http.delete(
      Uri.parse('$baseUrl/books/$bookId/notes/$noteId'),
      headers: _headers(),
    );
  }
}

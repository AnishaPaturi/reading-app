import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/tts_document.dart';

abstract class TtsRepository {
  Future<TtsDocument> extractText({
    required String bookId,
    required String fileId,
    int chapter = 1,
  });

  Future<TtsPosition?> getPosition({
    required String bookId,
    required String fileId,
  });

  Future<TtsPosition> savePosition({
    required String bookId,
    required String fileId,
    required TtsPosition position,
  });

  Future<void> resetPosition({
    required String bookId,
    required String fileId,
  });
}

class HttpTtsRepository implements TtsRepository {
  final String baseUrl;
  final String? Function() tokenProvider;

  HttpTtsRepository({
    String? baseUrl,
    required this.tokenProvider,
  }) : baseUrl = baseUrl ?? _resolveBaseUrl();

  static String _resolveBaseUrl() {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080/api/v1';
    return 'http://localhost:8080/api/v1';
  }

  Map<String, String> _headers() {
    final token = tokenProvider();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<TtsDocument> extractText({
    required String bookId,
    required String fileId,
    int chapter = 1,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/books/$bookId/files/$fileId/text?chapter=$chapter'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return TtsDocument.fromJson(data);
    }
    throw Exception('Failed to extract document text (HTTP ${res.statusCode})');
  }

  @override
  Future<TtsPosition?> getPosition({
    required String bookId,
    required String fileId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/books/$bookId/files/$fileId/tts-position'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return TtsPosition.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching TTS position: $e');
      return null;
    }
  }

  @override
  Future<TtsPosition> savePosition({
    required String bookId,
    required String fileId,
    required TtsPosition position,
  }) async {
    final payload = {
      'chapterIndex': position.chapterIndex,
      'chunkIndex': position.chunkIndex,
      'characterOffset': position.characterOffset,
      'progressPercentage': position.progressPercentage,
    };
    final res = await http.put(
      Uri.parse('$baseUrl/books/$bookId/files/$fileId/tts-position'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return TtsPosition.fromJson(data);
    }
    throw Exception('Failed to save TTS position (HTTP ${res.statusCode})');
  }

  @override
  Future<void> resetPosition({
    required String bookId,
    required String fileId,
  }) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/books/$bookId/files/$fileId/tts-position'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to reset TTS position (HTTP ${res.statusCode})');
    }
  }
}

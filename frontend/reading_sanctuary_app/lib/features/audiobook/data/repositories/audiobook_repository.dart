import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../models/audio_position.dart';

abstract class AudiobookRepository {
  Future<AudioPosition?> getPosition({
    required String bookId,
    required String fileId,
  });

  Future<AudioPosition> savePosition({
    required String bookId,
    required String fileId,
    required AudioPosition position,
    required bool isCompleted,
  });

  Future<void> resetPosition({
    required String bookId,
    required String fileId,
  });
}

class HttpAudiobookRepository implements AudiobookRepository {
  final String baseUrl;
  final String? Function() tokenProvider;

  HttpAudiobookRepository({
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
  Future<AudioPosition?> getPosition({
    required String bookId,
    required String fileId,
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/books/$bookId/files/$fileId/audio-position'),
        headers: _headers(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return AudioPosition.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching audio position: $e');
      return null;
    }
  }

  @override
  Future<AudioPosition> savePosition({
    required String bookId,
    required String fileId,
    required AudioPosition position,
    required bool isCompleted,
  }) async {
    final payload = {
      'positionMs': position.positionMs,
      'durationMs': position.durationMs,
      'playbackSpeed': position.playbackSpeed,
      'isCompleted': isCompleted,
    };
    final res = await http.put(
      Uri.parse('$baseUrl/books/$bookId/files/$fileId/audio-position'),
      headers: _headers(),
      body: jsonEncode(payload),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return AudioPosition.fromJson(data);
    }
    throw Exception('Failed to save audio position (HTTP ${res.statusCode})');
  }

  @override
  Future<void> resetPosition({
    required String bookId,
    required String fileId,
  }) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/books/$bookId/files/$fileId/audio-position'),
      headers: _headers(),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to reset audio position (HTTP ${res.statusCode})');
    }
  }
}

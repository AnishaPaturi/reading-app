import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ReaderFileService {
  final String baseUrl;
  final String? Function() tokenProvider;

  ReaderFileService({
    String? baseUrl,
    required this.tokenProvider,
  }) : baseUrl = baseUrl ?? _resolveBaseUrl();

  static String _resolveBaseUrl() {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080/api/v1';
    return 'http://localhost:8080/api/v1';
  }

  Future<Uint8List> loadFileBytes({
    required String bookId,
    required String fileId,
  }) async {
    final token = tokenProvider();
    final headers = <String, String>{
      'Accept': '*/*',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final url = Uri.parse('$baseUrl/books/$bookId/files/$fileId');
    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
      throw Exception('Failed to download document: HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('ReaderFileService download error: $e');
      rethrow;
    }
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../../../offline/services/download_manager.dart';

class ReaderFileService {
  final String baseUrl;
  final String? Function() tokenProvider;
  final DownloadManager? downloadManager;

  ReaderFileService({
    String? baseUrl,
    required this.tokenProvider,
    this.downloadManager,
  }) : baseUrl = baseUrl ?? _resolveBaseUrl();

  static String _resolveBaseUrl() => ApiConfig.baseUrl;

  Future<Uint8List> loadFileBytes({
    required String bookId,
    required String fileId,
  }) async {
    // 1. Check local offline storage first
    if (downloadManager != null) {
      final localBytes = await downloadManager!.getLocalFileBytes(fileId);
      if (localBytes != null && localBytes.isNotEmpty) {
        debugPrint('ReaderFileService loaded file $fileId from offline storage');
        return localBytes;
      }
    }

    // 2. Fetch from remote backend
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

      // If the file was not found with the requested fileId (e.g. placeholder or mismatched ID),
      // query the book's files list and retry downloading using the first available file.
      if (response.statusCode == 404) {
        debugPrint('ReaderFileService: 404 for $url. Checking file list for book $bookId...');
        final listUrl = Uri.parse('$baseUrl/books/$bookId/files');
        final listResponse = await http.get(listUrl, headers: headers);
        if (listResponse.statusCode == 200) {
          final dynamic filesJson = jsonDecode(listResponse.body);
          if (filesJson is List && filesJson.isNotEmpty) {
            final firstFile = filesJson.first;
            final realFileId = firstFile['id']?.toString();
            if (realFileId != null && realFileId != fileId) {
              debugPrint('ReaderFileService: Retrying with resolved fileId $realFileId');
              final retryUrl = Uri.parse('$baseUrl/books/$bookId/files/$realFileId');
              final retryResponse = await http.get(retryUrl, headers: headers);
              if (retryResponse.statusCode == 200 && retryResponse.bodyBytes.isNotEmpty) {
                return retryResponse.bodyBytes;
              }
            }
          }
        }
      }

      throw Exception('Failed to download document: HTTP ${response.statusCode}');
    } catch (e) {
      debugPrint('ReaderFileService download error: $e');
      rethrow;
    }
  }
}

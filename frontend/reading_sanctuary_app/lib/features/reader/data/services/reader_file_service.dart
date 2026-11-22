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
  }) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static final Map<String, Future<Uint8List>> _activeDownloads = {};

  Future<Uint8List> loadFileBytes({
    required String bookId,
    required String fileId,
  }) async {
    final key = '$bookId:$fileId';
    if (_activeDownloads.containsKey(key)) {
      debugPrint('ReaderFileService: Joining in-flight download for $key');
      return _activeDownloads[key]!;
    }

    final future = _loadFileBytesInternal(bookId: bookId, fileId: fileId);
    _activeDownloads[key] = future;
    try {
      return await future;
    } finally {
      _activeDownloads.remove(key);
    }
  }

  Future<Uint8List> _loadFileBytesInternal({
    required String bookId,
    required String fileId,
  }) async {
    if (bookId.trim().isEmpty || fileId.trim().isEmpty) {
      throw ArgumentError(
        'Both bookId and fileId are required to open a document.',
      );
    }

    // 1. Check offline storage first.
    if (downloadManager != null) {
      final localBytes =
          await downloadManager!.getLocalFileBytes(fileId);

      if (localBytes != null && localBytes.isNotEmpty) {
        debugPrint(
          'ReaderFileService: Loaded $fileId from offline storage.',
        );

        return localBytes;
      }
    }

    // 2. Retrieve authentication token.
    final token = tokenProvider();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Your session has expired. Please sign in again.',
      );
    }

    final headers = <String, String>{
      'Accept': 'application/octet-stream',
      'Authorization': 'Bearer $token',
    };

    // 3. Request the exact file ID.
    final url = Uri.parse(
      '$baseUrl/books/$bookId/files/$fileId',
    );

    debugPrint('ReaderFileService: Downloading $url');

    final response = await http.get(
      url,
      headers: headers,
    );

    // 4. Successful download.
    if (response.statusCode == 200) {
      if (response.bodyBytes.isEmpty) {
        throw Exception(
          'The requested document is empty.',
        );
      }

      debugPrint(
        'ReaderFileService: Download successful. '
        'Bytes: ${response.bodyBytes.length}',
      );

      return response.bodyBytes;
    }

    // 5. Report meaningful errors.
    if (response.statusCode == 401) {
      throw Exception(
        'Your session is unauthorized. Please sign in again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to access this file.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'The requested book file was not found. '
        'Please verify that the file is attached to this book '
        'and exists in backend storage.',
      );
    }

    throw Exception(
      'Failed to download document. '
      'HTTP ${response.statusCode}: ${response.body}',
    );
  }
}

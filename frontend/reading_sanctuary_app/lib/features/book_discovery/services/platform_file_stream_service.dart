import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../library/data/models/selected_book_file.dart';
import '../models/discovered_file.dart';
import 'stream/platform_stream.dart';

class PlatformFileStreamService {
  static const MethodChannel _androidChannel = MethodChannel('reading_sanctuary/saf');

  final MethodChannel? _channelOverride;

  PlatformFileStreamService({MethodChannel? channel}) : _channelOverride = channel;

  MethodChannel get _channel => _channelOverride ?? _androidChannel;

  /// Creates a SelectedBookFile configured for low-RAM streaming upload:
  /// - Android Content URIs: streamed through native ContentResolver chunks.
  /// - Desktop files: streamed through File.openRead().
  /// - Web files: in-memory bytes.
  Future<SelectedBookFile> createSelectedBookFile(DiscoveredFile file) async {
    // 1. Android Content URI
    if (!kIsWeb && file.pathOrUri.startsWith('content://')) {
      final stream = streamAndroidContentUri(file.pathOrUri, file.sizeBytes);
      return SelectedBookFile(
        name: file.name,
        extension: file.extension,
        size: file.sizeBytes,
        path: null, // Content URIs cannot be opened as dart:io paths
        readStream: stream,
      );
    }

    // 2. Desktop filesystem native streaming
    if (!kIsWeb && !file.pathOrUri.startsWith('web://')) {
      final stream = openDesktopFileStream(file.pathOrUri);
      return SelectedBookFile(
        name: file.name,
        extension: file.extension,
        size: file.sizeBytes,
        path: file.pathOrUri,
        readStream: stream,
      );
    }

    // 3. Web in-memory fallback
    return SelectedBookFile(
      name: file.name,
      extension: file.extension,
      size: file.sizeBytes,
      path: null,
      bytes: file.headerBytes ?? Uint8List(0),
    );
  }

  /// Streams chunks from Android ContentResolver sequentially in 64 KB blocks without buffering in RAM.
  /// Uses a persistent native stream session (openDocumentStream -> readDocumentStreamChunk -> closeDocumentStream).
  Stream<List<int>> streamAndroidContentUri(
    String uri,
    int totalSizeBytes, {
    int chunkSize = 65536,
  }) async* {
    String? sessionId;
    try {
      final dynamic sessionResult = await _channel.invokeMethod('openDocumentStream', {
        'uri': uri,
      });
      sessionId = sessionResult?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        return;
      }

      var totalRead = 0;
      while (totalRead < totalSizeBytes) {
        final toRead = (totalSizeBytes - totalRead).clamp(0, chunkSize);
        final dynamic raw = await _channel.invokeMethod('readDocumentStreamChunk', {
          'sessionId': sessionId,
          'length': toRead,
        });

        if (raw == null || raw is! List || raw.isEmpty) {
          break;
        }

        final bytes = raw is Uint8List ? raw : Uint8List.fromList(List<int>.from(raw));
        totalRead += bytes.length;
        yield bytes;
      }
    } catch (e) {
      debugPrint('Error streaming Android SAF URI $uri: $e');
    } finally {
      if (sessionId != null) {
        try {
          await _channel.invokeMethod('closeDocumentStream', {
            'sessionId': sessionId,
          });
        } catch (_) {}
      }
    }
  }
}

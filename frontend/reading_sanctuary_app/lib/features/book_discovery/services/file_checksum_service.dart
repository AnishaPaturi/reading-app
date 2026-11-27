import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../models/discovered_file.dart';
import 'hasher/desktop_hasher.dart';

class FileChecksumService {
  static const MethodChannel _androidChannel = MethodChannel('reading_sanctuary/saf');
  static const Uuid _uuid = Uuid();

  final MethodChannel? _channelOverride;
  final Map<String, String> _checksumCache = {};
  String _currentSessionId = _uuid.v4();

  FileChecksumService({MethodChannel? channel}) : _channelOverride = channel;

  MethodChannel get _channel => _channelOverride ?? _androidChannel;

  String get currentSessionId => _currentSessionId;

  /// Starts a new discovery session.
  /// Drops session-scoped cache entries for files with unreliable modification metadata,
  /// while preserving reliable metadata entries across sessions.
  void startNewSession([String? newSessionId]) {
    _currentSessionId = newSessionId ?? _uuid.v4();
    _checksumCache.removeWhere((key, _) => key.startsWith('session:'));
  }

  /// Builds a deterministic cache key.
  /// - Reliable metadata (Desktop / verified SAF): includes path, size, and last modified millis.
  /// - Unreliable metadata (unverified SAF / dynamic URIs): scoped strictly to the current discovery session.
  String buildCacheKey(DiscoveredFile file) {
    if (file.hasReliableMetadata) {
      return 'reliable:${file.pathOrUri}:${file.sizeBytes}:${file.lastModified.millisecondsSinceEpoch}';
    } else {
      return 'session:$_currentSessionId:${file.pathOrUri}';
    }
  }

  /// Calculates SHA-256 for a discovered file using streaming to prevent high memory usage.
  /// Employs smart cache invalidation:
  /// - Recalculates if file size or last-modified timestamp changes.
  /// - Isolates files with unreliable metadata to the current discovery session.
  Future<String?> computeChecksum(DiscoveredFile file) async {
    final cacheKey = buildCacheKey(file);

    if (_checksumCache.containsKey(cacheKey)) {
      return _checksumCache[cacheKey];
    }

    String? computed;

    try {
      // 1. Android Content URI handling
      if (!kIsWeb && file.pathOrUri.startsWith('content://')) {
        computed = await _computeAndroidSafSha256(file.pathOrUri);
      }
      // 2. Desktop native filesystem streaming
      else if (!kIsWeb && !file.pathOrUri.startsWith('web://')) {
        computed = await computeIoFileSha256(file.pathOrUri);
      }
      // 3. Web or in-memory fallback
      else if (file.headerBytes != null && file.headerBytes!.isNotEmpty) {
        computed = sha256.convert(file.headerBytes!).toString();
      }

      if (computed != null && computed.isNotEmpty) {
        _checksumCache[cacheKey] = computed;
      }
      return computed;
    } catch (e) {
      debugPrint('Error computing SHA-256 for ${file.name}: $e');
      return null;
    }
  }

  Future<String?> _computeAndroidSafSha256(String contentUri) async {
    try {
      final dynamic raw = await _channel.invokeMethod('computeDocumentSha256', {
        'uri': contentUri,
      });
      return raw as String?;
    } on PlatformException catch (e) {
      debugPrint('Native Android SHA-256 error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Android SHA-256 error: $e');
      return null;
    }
  }

  /// Clears all entries in the in-memory checksum cache.
  void clearCache() {
    _checksumCache.clear();
  }

  /// Manually populate cache (e.g. for testing)
  void setCachedChecksum(
    String pathOrUri,
    int sizeBytes,
    DateTime modified,
    String checksum, {
    bool hasReliableMetadata = true,
  }) {
    final key = hasReliableMetadata
        ? 'reliable:$pathOrUri:$sizeBytes:${modified.millisecondsSinceEpoch}'
        : 'session:$_currentSessionId:$pathOrUri';
    _checksumCache[key] = checksum;
  }
}

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../models/discovered_file.dart';
import '../../models/scan_folder.dart';
import 'platform_book_scanner.dart';

class AndroidBookScanner implements PlatformBookScanner {
  static const MethodChannel _channel = MethodChannel('reading_sanctuary/saf');
  static const Uuid _uuid = Uuid();

  final MethodChannel channel;

  AndroidBookScanner({MethodChannel? channel}) : channel = channel ?? _channel;

  @override
  String get platformCapabilitiesDescription =>
      'Android Storage Access Framework (SAF) provides secure, persistent folder access '
      'that survives application restarts without requiring broad storage permissions.';

  @override
  Future<ScanFolder?> pickFolder() async {
    try {
      final dynamic raw = await channel.invokeMethod('openDocumentTree');
      if (raw == null || raw is! Map) return null;

      final map = Map<String, dynamic>.from(raw);
      final uri = map['uri'] as String?;
      final name = map['name'] as String? ?? 'Folder';

      if (uri == null || uri.isEmpty) return null;

      return ScanFolder(
        id: _uuid.v4(),
        name: name,
        pathOrUri: uri,
        isDefault: false,
        folderType: _inferFolderType(name, uri),
        status: FolderAccessStatus.active,
      );
    } on PlatformException catch (e) {
      if (e.code == 'BUSY') rethrow;
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DiscoveredFile>> scanFolder(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async {
    try {
      final dynamic rawList = await channel.invokeMethod('listFiles', {
        'uri': folder.pathOrUri,
        'extensions': supportedExtensions.toList(),
      });

      if (rawList == null || rawList is! List) return [];

      final results = <DiscoveredFile>[];
      for (final rawItem in rawList) {
        if (rawItem is! Map) continue;
        final map = Map<String, dynamic>.from(rawItem);
        final uri = map['uri'] as String?;
        final name = map['name'] as String?;
        final ext = (map['extension'] as String? ?? '').toLowerCase();
        final size = (map['size'] as num?)?.toInt() ?? 0;
        final modMillis = (map['lastModified'] as num?)?.toInt() ?? 0;

        if (uri == null || name == null || ext.isEmpty) continue;

        results.add(
          DiscoveredFile(
            id: _uuid.v5(Namespace.url.value, uri),
            name: name,
            pathOrUri: uri,
            extension: ext,
            sizeBytes: size,
            lastModified: modMillis > 0
                ? DateTime.fromMillisecondsSinceEpoch(modMillis)
                : DateTime.now(),
            parentFolderIdentifier: folder.pathOrUri,
            hasReliableMetadata: modMillis > 0 && size > 0,
          ),
        );
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  @override
  Stream<DiscoveredFile> scanFolderStream(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async* {
    final files = await scanFolder(folder, supportedExtensions: supportedExtensions);
    for (final file in files) {
      yield file;
    }
  }

  @override
  Future<bool> verifyPermission(ScanFolder folder) async {
    try {
      final dynamic granted = await channel.invokeMethod('isUriPermissionGranted', {
        'uri': folder.pathOrUri,
      });
      return granted == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> releasePermission(ScanFolder folder) async {
    try {
      final dynamic released = await channel.invokeMethod('releasePersistableUriPermission', {
        'uri': folder.pathOrUri,
      });
      return released == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12}) async {
    try {
      final dynamic bytes = await channel.invokeMethod('readFileHeader', {
        'uri': pathOrUri,
        'maxBytes': maxBytes,
      });
      if (bytes is Uint8List) return bytes;
      if (bytes is List) return Uint8List.fromList(bytes.cast<int>());
      return null;
    } catch (_) {
      return null;
    }
  }

  FolderType _inferFolderType(String name, String uri) {
    final lower = '$name $uri'.toLowerCase();
    if (lower.contains('download')) return FolderType.downloads;
    if (lower.contains('document')) return FolderType.documents;
    return FolderType.custom;
  }
}

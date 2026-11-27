import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/discovered_file.dart';
import '../../models/scan_folder.dart';
import 'platform_book_scanner.dart';

class DesktopBookScanner implements PlatformBookScanner {
  static const Uuid _uuid = Uuid();

  @override
  String get platformCapabilitiesDescription =>
      'Desktop filesystem scanning traverses your local folders directly with native filesystem permissions.';

  @override
  Future<ScanFolder?> pickFolder() async {
    try {
      final selectedPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Books or Audiobooks Folder',
      );
      if (selectedPath == null || selectedPath.trim().isEmpty) return null;

      final dir = Directory(selectedPath);
      final exists = await dir.exists();
      if (!exists) return null;

      final name = dir.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? dir.path;

      return ScanFolder(
        id: _uuid.v4(),
        name: name,
        pathOrUri: dir.path,
        isDefault: false,
        folderType: _inferFolderType(dir.path),
        status: FolderAccessStatus.active,
      );
    } catch (e) {
      debugPrint('Error picking desktop folder: $e');
      return null;
    }
  }

  @override
  Future<List<DiscoveredFile>> scanFolder(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async {
    final results = <DiscoveredFile>[];
    await for (final file in scanFolderStream(folder, supportedExtensions: supportedExtensions)) {
      results.add(file);
    }
    return results;
  }

  @override
  Stream<DiscoveredFile> scanFolderStream(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async* {
    final rootDir = Directory(folder.pathOrUri);
    if (!await rootDir.exists()) return;

    final normalizedExts = supportedExtensions.map((e) => e.toLowerCase().replaceAll('.', '')).toSet();

    // Queue-based BFS traversal to handle inaccessible directories gracefully
    final queue = <Directory>[rootDir];
    final visitedPaths = <String>{};
    var depth = 0;
    const maxDepth = 15;

    while (queue.isNotEmpty && depth < maxDepth) {
      final currentLevel = List<Directory>.from(queue);
      queue.clear();

      for (final currentDir in currentLevel) {
        if (!visitedPaths.add(currentDir.path)) continue;

        try {
          final entities = currentDir.listSync(followLinks: false);

          for (final entity in entities) {
            try {
              final basename = entity.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';

              // Skip hidden or system folders and files
              if (_isIgnoredPath(basename)) continue;

              if (entity is Directory) {
                queue.add(entity);
              } else if (entity is File) {
                final dotIndex = basename.lastIndexOf('.');
                if (dotIndex > 0 && dotIndex < basename.length - 1) {
                  final ext = basename.substring(dotIndex + 1).toLowerCase();
                  if (normalizedExts.contains(ext)) {
                    final stat = entity.statSync();
                    final id = _uuid.v5(Namespace.url.value, entity.path);

                    yield DiscoveredFile(
                      id: id,
                      name: basename,
                      pathOrUri: entity.path,
                      extension: ext,
                      sizeBytes: stat.size,
                      lastModified: stat.modified,
                      parentFolderIdentifier: folder.pathOrUri,
                    );
                  }
                }
              }
            } catch (_) {
              // Individual file read error - continue
            }
          }
        } on FileSystemException catch (e) {
          // Inaccessible directory - skip individually without terminating scan
          debugPrint('Skipping inaccessible directory ${currentDir.path}: $e');
        } catch (e) {
          debugPrint('Error listing directory ${currentDir.path}: $e');
        }
      }
      depth++;
    }
  }

  @override
  Future<bool> verifyPermission(ScanFolder folder) async {
    try {
      final dir = Directory(folder.pathOrUri);
      return await dir.exists();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> releasePermission(ScanFolder folder) async {
    return true;
  }

  @override
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12}) async {
    try {
      final file = File(pathOrUri);
      if (!await file.exists()) return null;
      final raf = await file.open(mode: FileMode.read);
      try {
        final bytes = await raf.read(maxBytes);
        return bytes;
      } finally {
        await raf.close();
      }
    } catch (e) {
      debugPrint('Error reading file header for $pathOrUri: $e');
      return null;
    }
  }

  bool _isIgnoredPath(String name) {
    if (name.isEmpty) return true;
    if (name.startsWith('.')) return true; // .git, .cache, .DS_Store
    final lower = name.toLowerCase();
    return lower == 'system volume information' ||
        lower == '\$recycle.bin' ||
        lower == 'node_modules' ||
        lower == 'appdata' ||
        lower == 'recovery';
  }

  FolderType _inferFolderType(String path) {
    final lower = path.toLowerCase();
    if (lower.contains('download')) return FolderType.downloads;
    if (lower.contains('document')) return FolderType.documents;
    return FolderType.custom;
  }
}

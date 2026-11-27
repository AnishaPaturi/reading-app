import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/download_task.dart';
import 'download_manager.dart';

enum DownloadsScanStatus {
  success,
  directoryNotFound,
  permissionDenied,
  error,
}

class DownloadsScanResult {
  final DownloadsScanStatus status;
  final List<DownloadTask> discoveredTasks;
  final String? scannedPath;
  final String? errorMessage;

  const DownloadsScanResult({
    required this.status,
    this.discoveredTasks = const [],
    this.scannedPath,
    this.errorMessage,
  });

  bool get isSuccess => status == DownloadsScanStatus.success;
  bool get isPermissionDenied => status == DownloadsScanStatus.permissionDenied;
  int get count => discoveredTasks.length;
}

class DownloadsScannerService extends ChangeNotifier {
  static const Uuid _uuid = Uuid();

  static const Set<String> defaultSupportedFormats = {
    'epub',
    'pdf',
    'mobi',
    'azw3',
    'fb2',
    'txt',
    'doc',
    'docx',
    'rtf',
    'mp3',
    'm4b',
    'm4a',
  };

  final DownloadManager downloadManager;
  final Set<String> supportedFormats;
  final String? customDownloadsPath;

  bool _isScanning = false;
  DownloadsScanResult? _lastResult;

  DownloadsScannerService({
    required this.downloadManager,
    this.supportedFormats = defaultSupportedFormats,
    this.customDownloadsPath,
  });

  bool get isScanning => _isScanning;
  DownloadsScanResult? get lastResult => _lastResult;

  /// Resolves the device's Downloads directory path across platforms.
  Future<String?> resolveDownloadsDirectoryPath() async {
    if (customDownloadsPath != null && customDownloadsPath!.isNotEmpty) {
      return customDownloadsPath;
    }

    // Direct environment paths checked first to avoid platform channel delays
    if (!kIsWeb && Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final d = Directory('$userProfile\\Downloads');
        if (d.existsSync()) {
          return d.path;
        }
      }
    }

    if (!kIsWeb && (Platform.isMacOS || Platform.isLinux)) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final d = Directory('$home/Downloads');
        if (d.existsSync()) {
          return d.path;
        }
      }
    }

    if (!kIsWeb && Platform.isAndroid) {
      final candidates = [
        '/storage/emulated/0/Download',
        '/sdcard/Download',
        '/storage/emulated/0/Downloads',
      ];
      for (final p in candidates) {
        try {
          final d = Directory(p);
          if (d.existsSync()) {
            return d.path;
          }
        } catch (_) {}
      }
    }

    try {
      final dir = await getDownloadsDirectory().timeout(const Duration(milliseconds: 300));
      if (dir != null && await dir.exists()) {
        return dir.path;
      }
    } catch (_) {}

    return null;
  }

  /// Scans the device's Downloads directory for supported ebooks and audiobooks.
  /// Automatically registers discovered files in [DownloadManager] while avoiding duplicates.
  /// Never moves or modifies the original files.
  /// Never fabricates download dates for discovered files.
  Future<DownloadsScanResult> scanDownloadsFolder({
    String? overridePath,
  }) async {
    if (_isScanning) {
      return _lastResult ??
          const DownloadsScanResult(status: DownloadsScanStatus.error);
    }

    _isScanning = true;
    notifyListeners();

    try {
      final targetPath = overridePath ?? await resolveDownloadsDirectoryPath();

      if (targetPath == null || targetPath.trim().isEmpty) {
        _lastResult = const DownloadsScanResult(
          status: DownloadsScanStatus.directoryNotFound,
          errorMessage: 'Downloads directory could not be located on this device.',
        );
        return _lastResult!;
      }

      final dir = Directory(targetPath);
      final exists = await dir.exists();
      if (!exists) {
        _lastResult = DownloadsScanResult(
          status: DownloadsScanStatus.directoryNotFound,
          scannedPath: targetPath,
          errorMessage: 'Directory "$targetPath" does not exist.',
        );
        return _lastResult!;
      }

      // Test readability / permission
      try {
        dir.listSync(followLinks: false);
      } on FileSystemException catch (e) {
        _lastResult = DownloadsScanResult(
          status: DownloadsScanStatus.permissionDenied,
          scannedPath: targetPath,
          errorMessage: 'Storage access denied: ${e.message}',
        );
        return _lastResult!;
      }

      final discovered = <DownloadTask>[];
      final normalizedExts = supportedFormats
          .map((e) => e.toLowerCase().replaceAll('.', ''))
          .toSet();

      const ignoredFolders = {
        'node_modules',
        '.git',
        'build',
        'appdata',
        'programs',
        'temp',
        'cache',
        'windows',
        'system32',
      };

      // Traverse directory up to 3 levels deep
      final queue = <Directory>[dir];
      final visited = <String>{};
      int depth = 0;
      const maxDepth = 3;
      const maxDiscoveredFiles = 300;

      while (queue.isNotEmpty && depth < maxDepth && discovered.length < maxDiscoveredFiles) {
        final currentLevel = List<Directory>.from(queue);
        queue.clear();
        depth++;

        for (final currentDir in currentLevel) {
          if (!visited.add(currentDir.path.toLowerCase())) continue;
          if (discovered.length >= maxDiscoveredFiles) break;

          try {
            final entities = currentDir.listSync(followLinks: false);
            for (final entity in entities) {
              if (discovered.length >= maxDiscoveredFiles) break;

              final basename = entity.uri.pathSegments
                      .where((s) => s.isNotEmpty)
                      .lastOrNull ??
                  '';

              // Skip hidden or heavy non-document folders
              if (basename.startsWith('.') ||
                  ignoredFolders.contains(basename.toLowerCase())) {
                continue;
              }

              if (entity is Directory) {
                queue.add(entity);
              } else if (entity is File) {
                final dotIndex = basename.lastIndexOf('.');
                if (dotIndex > 0 && dotIndex < basename.length - 1) {
                  final ext = basename.substring(dotIndex + 1).toLowerCase();
                  if (normalizedExts.contains(ext)) {
                    try {
                      final stat = entity.statSync();
                      if (stat.size <= 0) continue;

                      final deterministicId = _uuid.v5(
                        Namespace.url.value,
                        'downloads:${entity.path.replaceAll('\\', '/')}',
                      );

                      final cleanTitle = _cleanTitleFromFileName(basename, ext);

                      discovered.add(
                        DownloadTask(
                          fileId: deterministicId,
                          bookId: deterministicId,
                          bookTitle: cleanTitle,
                          fileName: basename,
                          format: ext.toUpperCase(),
                          localPath: entity.path,
                          totalBytes: stat.size,
                          downloadedBytes: stat.size,
                          status: DownloadStatus.downloaded,
                          source: DownloadSource.folderDiscovered,
                          isDiscovered: true,
                          discoveredAt: DateTime.now(),
                          fileLastModified: stat.modified,
                          downloadedAt: null, // Never fabricate download dates!
                        ),
                      );
                    } catch (_) {}
                  }
                }
              }
            }
          } catch (_) {}
        }
      }

      // Register with DownloadManager to merge and prevent duplicates
      await downloadManager.registerDiscoveredBooks(discovered);

      _lastResult = DownloadsScanResult(
        status: DownloadsScanStatus.success,
        discoveredTasks: discovered,
        scannedPath: targetPath,
      );

      return _lastResult!;
    } catch (e) {
      debugPrint('DownloadsScannerService scan error: $e');
      _lastResult = DownloadsScanResult(
        status: DownloadsScanStatus.error,
        errorMessage: e.toString(),
      );
      return _lastResult!;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  String _cleanTitleFromFileName(String fileName, String ext) {
    var title = fileName.substring(0, fileName.length - (ext.length + 1));
    title = title.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (title.isEmpty) return fileName;
    // Capitalize words
    return title.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}

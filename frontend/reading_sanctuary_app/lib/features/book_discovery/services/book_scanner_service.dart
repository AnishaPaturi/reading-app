import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/discovered_file.dart';
import '../models/scan_folder.dart';
import 'folder_manager_service.dart';
import 'platform/android_book_scanner.dart';
import 'platform/desktop_book_scanner.dart';
import 'platform/platform_book_scanner.dart';
import 'platform/web_book_scanner.dart';

class ScanProgress {
  final bool isScanning;
  final String? currentFolderName;
  final int filesDiscovered;
  final String? error;

  const ScanProgress({
    required this.isScanning,
    this.currentFolderName,
    this.filesDiscovered = 0,
    this.error,
  });
}

class BookScannerService extends ChangeNotifier {
  static const Set<String> defaultSupportedExtensions = {
    'pdf',
    'epub',
    'docx',
    'mp3',
    'm4b',
    'm4a',
  };

  final PlatformBookScanner scanner;
  final FolderManagerService folderManager;
  final Set<String> supportedExtensions;

  bool _isScanning = false;
  String? _currentFolderName;
  final List<DiscoveredFile> _discoveredFiles = [];
  String? _lastError;

  BookScannerService({
    required this.scanner,
    required this.folderManager,
    this.supportedExtensions = defaultSupportedExtensions,
  });

  factory BookScannerService.create({
    PlatformBookScanner? customScanner,
    FolderManagerService? customFolderManager,
  }) {
    final effectiveScanner = customScanner ?? createDefaultPlatformScanner();
    final effectiveFolderManager = customFolderManager ?? FolderManagerService(scanner: effectiveScanner);
    return BookScannerService(
      scanner: effectiveScanner,
      folderManager: effectiveFolderManager,
    );
  }

  static PlatformBookScanner createDefaultPlatformScanner() {
    if (kIsWeb) {
      return WebBookScanner();
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidBookScanner();
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      default:
        return DesktopBookScanner();
    }
  }

  bool get isScanning => _isScanning;
  String? get currentFolderName => _currentFolderName;
  List<DiscoveredFile> get discoveredFiles => List.unmodifiable(_discoveredFiles);
  String? get lastError => _lastError;

  ScanProgress get progress => ScanProgress(
    isScanning: _isScanning,
    currentFolderName: _currentFolderName,
    filesDiscovered: _discoveredFiles.length,
    error: _lastError,
  );

  /// Scans all active registered folders and aggregates discovered books.
  Future<List<DiscoveredFile>> scanAllFolders() async {
    if (_isScanning) return _discoveredFiles;

    _isScanning = true;
    _lastError = null;
    notifyListeners();

    final allDiscovered = <String, DiscoveredFile>{};

    try {
      if (!folderManager.isInitialized) {
        await folderManager.initialize();
      }

      final targetFolders = folderManager.activeFolders;

      for (final folder in targetFolders) {
        _currentFolderName = folder.name;
        notifyListeners();

        try {
          final files = await scanner.scanFolder(
            folder,
            supportedExtensions: supportedExtensions,
          );

          for (final f in files) {
            allDiscovered[f.pathOrUri] = f;
          }

          await folderManager.updateFolderScanStats(folder.id, files.length);
        } catch (e) {
          debugPrint('Error scanning folder ${folder.name}: $e');
        }
      }

      _discoveredFiles.clear();
      _discoveredFiles.addAll(allDiscovered.values);
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Error in scanAllFolders: $e');
    } finally {
      _isScanning = false;
      _currentFolderName = null;
      notifyListeners();
    }

    return List.unmodifiable(_discoveredFiles);
  }

  /// Scans a single folder.
  Future<List<DiscoveredFile>> scanSingleFolder(ScanFolder folder) async {
    _isScanning = true;
    _currentFolderName = folder.name;
    _lastError = null;
    notifyListeners();

    try {
      final files = await scanner.scanFolder(
        folder,
        supportedExtensions: supportedExtensions,
      );

      await folderManager.updateFolderScanStats(folder.id, files.length);

      // Merge into discovered files without duplicates
      final existingMap = {for (final f in _discoveredFiles) f.pathOrUri: f};
      for (final f in files) {
        existingMap[f.pathOrUri] = f;
      }
      _discoveredFiles.clear();
      _discoveredFiles.addAll(existingMap.values);

      return files;
    } catch (e) {
      _lastError = e.toString();
      return [];
    } finally {
      _isScanning = false;
      _currentFolderName = null;
      notifyListeners();
    }
  }

  /// Live progressive stream of discovered files for a folder.
  Stream<DiscoveredFile> scanFolderStream(ScanFolder folder) {
    return scanner.scanFolderStream(
      folder,
      supportedExtensions: supportedExtensions,
    );
  }

  /// Clears in-memory scan results.
  void clearResults() {
    _discoveredFiles.clear();
    _lastError = null;
    notifyListeners();
  }
}

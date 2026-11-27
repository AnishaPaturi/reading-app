import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/discovered_file.dart';
import '../../models/scan_folder.dart';
import 'platform_book_scanner.dart';

class WebBookScanner implements PlatformBookScanner {
  static const Uuid _uuid = Uuid();
  final List<DiscoveredFile> _inMemoryFiles = [];

  List<DiscoveredFile> get inMemoryFiles => List.unmodifiable(_inMemoryFiles);

  @override
  String get platformCapabilitiesDescription =>
      'Web browsers operate within a secure sandbox and cannot automatically scan local storage or Downloads folders in the background. '
      'Use the file or folder selector to choose books directly from your computer.';

  @override
  Future<ScanFolder?> pickFolder() async {
    try {
      // 1. Try directory picker if browser supports Directory picker (File System Access API)
      final dirPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Books Directory',
      );

      if (dirPath != null && dirPath.isNotEmpty) {
        return ScanFolder(
          id: _uuid.v4(),
          name: dirPath.split('/').lastOrNull ?? 'Web Folder',
          pathOrUri: dirPath,
          isDefault: false,
          folderType: FolderType.custom,
          status: FolderAccessStatus.active,
        );
      }

      // 2. Fallback: prompt user to pick multiple files
      final result = await pickFilesManually();
      if (result.isNotEmpty) {
        return ScanFolder(
          id: _uuid.v4(),
          name: 'Web Selected Files (${result.length})',
          pathOrUri: 'web_session://${DateTime.now().millisecondsSinceEpoch}',
          isDefault: false,
          folderType: FolderType.custom,
          status: FolderAccessStatus.active,
          discoveredCount: result.length,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Web folder pick note: $e');
      return null;
    }
  }

  /// Explicit multi-file selection for Web
  Future<List<DiscoveredFile>> pickFilesManually({
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedExtensions.toList(),
        allowMultiple: true,
        withData: false,
        withReadStream: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final list = <DiscoveredFile>[];
      for (final file in result.files) {
        final ext = (file.extension ?? '').toLowerCase();
        if (!supportedExtensions.contains(ext)) continue;

        final discovered = DiscoveredFile(
          id: _uuid.v4(),
          name: file.name,
          pathOrUri: file.path ?? 'web://${file.name}',
          extension: ext,
          sizeBytes: file.size,
          lastModified: DateTime.now(),
          parentFolderIdentifier: 'web_manual_selection',
          headerBytes: file.bytes != null && file.bytes!.length >= 12
              ? file.bytes!.sublist(0, 12)
              : null,
        );
        list.add(discovered);
      }

      _inMemoryFiles.clear();
      _inMemoryFiles.addAll(list);
      return list;
    } catch (e) {
      debugPrint('Web pickFiles error: $e');
      return [];
    }
  }

  @override
  Future<List<DiscoveredFile>> scanFolder(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async {
    return _inMemoryFiles
        .where((f) => supportedExtensions.contains(f.extension.toLowerCase()))
        .toList();
  }

  @override
  Stream<DiscoveredFile> scanFolderStream(
    ScanFolder folder, {
    Set<String> supportedExtensions = const {'pdf', 'epub', 'docx', 'mp3', 'm4b', 'm4a'},
  }) async* {
    for (final file in _inMemoryFiles) {
      if (supportedExtensions.contains(file.extension.toLowerCase())) {
        yield file;
      }
    }
  }

  @override
  Future<bool> verifyPermission(ScanFolder folder) async {
    return _inMemoryFiles.isNotEmpty;
  }

  @override
  Future<bool> releasePermission(ScanFolder folder) async {
    _inMemoryFiles.clear();
    return true;
  }

  @override
  Future<Uint8List?> readFileHeader(String pathOrUri, {int maxBytes = 12}) async {
    final match = _inMemoryFiles.where((f) => f.pathOrUri == pathOrUri).firstOrNull;
    return match?.headerBytes;
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_folder.dart';
import 'platform/platform_book_scanner.dart';

class FolderManagerService extends ChangeNotifier {
  static const String _storageKey = 'reading_sanctuary_scan_folders_v1';

  final PlatformBookScanner scanner;
  final SharedPreferences? _prefs;

  List<ScanFolder> _folders = [];
  bool _isInitialized = false;

  FolderManagerService({
    required this.scanner,
    SharedPreferences? prefs,
  }) : _prefs = prefs;

  List<ScanFolder> get folders => List.unmodifiable(_folders);
  List<ScanFolder> get activeFolders => _folders.where((f) => f.isAccessible).toList();
  bool get isInitialized => _isInitialized;

  /// Loads folders from persistence and verifies permissions.
  Future<void> initialize() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_storageKey);

    if (rawList != null && rawList.isNotEmpty) {
      final loaded = <ScanFolder>[];
      for (final rawJson in rawList) {
        try {
          final map = jsonDecode(rawJson) as Map<String, dynamic>;
          final folder = ScanFolder.fromJson(map);
          loaded.add(folder);
        } catch (_) {}
      }
      _folders = loaded;
    }

    // Verify all permissions against live system to detect revoked access
    await verifyAllPermissions();

    _isInitialized = true;
    notifyListeners();
  }

  /// Verifies live permission access for all registered folders.
  Future<void> verifyAllPermissions() async {
    final updated = <ScanFolder>[];
    for (final folder in _folders) {
      final isGranted = await scanner.verifyPermission(folder);
      final newStatus = isGranted ? FolderAccessStatus.active : FolderAccessStatus.permissionRevoked;
      updated.add(folder.copyWith(status: newStatus));
    }
    _folders = updated;
    await _persist();
    notifyListeners();
  }

  /// Prompts user to pick a folder and registers it.
  Future<ScanFolder?> pickAndRegisterFolder() async {
    final folder = await scanner.pickFolder();
    if (folder == null) return null;

    final existingIndex = _folders.indexWhere(
      (f) => f.pathOrUri.toLowerCase() == folder.pathOrUri.toLowerCase(),
    );

    if (existingIndex >= 0) {
      // Re-activate existing folder if it was already registered
      _folders[existingIndex] = _folders[existingIndex].copyWith(
        status: FolderAccessStatus.active,
        name: folder.name,
      );
      await _persist();
      notifyListeners();
      return _folders[existingIndex];
    }

    _folders.add(folder);
    await _persist();
    notifyListeners();
    return folder;
  }

  /// Explicitly registers a folder directly.
  Future<bool> registerFolder(ScanFolder folder) async {
    final exists = _folders.any(
      (f) => f.pathOrUri.toLowerCase() == folder.pathOrUri.toLowerCase(),
    );
    if (exists) return false;

    _folders.add(folder);
    await _persist();
    notifyListeners();
    return true;
  }

  /// Removes a folder and releases any persistent platform permission.
  Future<bool> removeFolder(String folderId) async {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index < 0) return false;

    final folder = _folders[index];
    await scanner.releasePermission(folder);

    _folders.removeAt(index);
    await _persist();
    notifyListeners();
    return true;
  }

  /// Reconnects a folder when permission has been revoked or lost.
  Future<bool> reconnectFolder(String folderId) async {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index < 0) return false;

    // Prompt user to re-grant permission
    final picked = await scanner.pickFolder();
    if (picked == null) return false;

    _folders[index] = _folders[index].copyWith(
      pathOrUri: picked.pathOrUri,
      name: picked.name,
      status: FolderAccessStatus.active,
    );
    await _persist();
    notifyListeners();
    return true;
  }

  /// Updates scan statistics (e.g. books discovered count)
  Future<void> updateFolderScanStats(String folderId, int discoveredCount) async {
    final index = _folders.indexWhere((f) => f.id == folderId);
    if (index < 0) return;

    _folders[index] = _folders[index].copyWith(
      lastScannedAt: DateTime.now(),
      discoveredCount: discoveredCount,
    );
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final jsonList = _folders.map((f) => jsonEncode(f.toJson())).toList();
    await prefs.setStringList(_storageKey, jsonList);
  }
}

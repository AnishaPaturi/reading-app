import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sync_models.dart';
import '../../../features/offline/domain/models/download_task.dart';

class LocalStorageDb {
  final String? customDirectoryPath;
  Directory? _baseDir;
  bool _initialized = false;

  final List<SyncChangeItem> _outbox = [];
  final List<SyncConflictItem> _conflicts = [];
  final Map<String, DownloadTask> _downloads = {};
  final Map<String, dynamic> _metadata = {};
  final Map<String, Map<String, dynamic>> _offlineEntities = {};

  LocalStorageDb({this.customDirectoryPath});

  Future<void> init() async {
    if (_initialized) return;

    try {
      if (customDirectoryPath != null) {
        _baseDir = Directory(customDirectoryPath!);
      } else {
        _baseDir = await getApplicationDocumentsDirectory();
      }

      if (!await _baseDir!.exists()) {
        await _baseDir!.create(recursive: true);
      }

      await _loadState();
    } catch (e) {
      debugPrint('LocalStorageDb fallback to in-memory state: $e');
    }

    _initialized = true;
  }

  File _getFile(String filename) {
    final path = _baseDir != null ? '${_baseDir!.path}/$filename' : filename;
    return File(path);
  }

  Future<void> _loadState() async {
    try {
      final metaFile = _getFile('sanctuary_metadata.json');
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        _metadata.addAll(jsonDecode(content) as Map<String, dynamic>);
      }

      final outboxFile = _getFile('sanctuary_outbox.json');
      if (await outboxFile.exists()) {
        final content = await outboxFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _outbox.clear();
        _outbox.addAll(list.map((e) => SyncChangeItem.fromJson(e as Map<String, dynamic>)));
      }

      final conflictsFile = _getFile('sanctuary_conflicts.json');
      if (await conflictsFile.exists()) {
        final content = await conflictsFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _conflicts.clear();
        _conflicts.addAll(list.map((e) => SyncConflictItem.fromJson(e as Map<String, dynamic>)));
      }

      final downloadsFile = _getFile('sanctuary_downloads.json');
      if (await downloadsFile.exists()) {
        final content = await downloadsFile.readAsString();
        final map = jsonDecode(content) as Map<String, dynamic>;
        _downloads.clear();
        map.forEach((k, v) {
          _downloads[k] = DownloadTask.fromJson(v as Map<String, dynamic>);
        });
      }
    } catch (e) {
      debugPrint('Error reading persisted sanctuary local state: $e');
    }
  }

  Future<void> _saveMetadata() async {
    try {
      if (_baseDir != null) {
        await _getFile('sanctuary_metadata.json').writeAsString(jsonEncode(_metadata));
      }
    } catch (e) {
      debugPrint('Error saving metadata: $e');
    }
  }

  Future<void> _saveOutbox() async {
    try {
      if (_baseDir != null) {
        final data = _outbox.map((e) => e.toJson()).toList();
        await _getFile('sanctuary_outbox.json').writeAsString(jsonEncode(data));
      }
    } catch (e) {
      debugPrint('Error saving outbox: $e');
    }
  }

  Future<void> _saveConflicts() async {
    try {
      if (_baseDir != null) {
        final data = _conflicts.map((e) => e.toJson()).toList();
        await _getFile('sanctuary_conflicts.json').writeAsString(jsonEncode(data));
      }
    } catch (e) {
      debugPrint('Error saving conflicts: $e');
    }
  }

  Future<void> _saveDownloads() async {
    try {
      if (_baseDir != null) {
        final data = _downloads.map((k, v) => MapEntry(k, v.toJson()));
        await _getFile('sanctuary_downloads.json').writeAsString(jsonEncode(data));
      }
    } catch (e) {
      debugPrint('Error saving downloads: $e');
    }
  }

  // --- Device & Cursor ---

  String? getDeviceId() => _metadata['deviceId'] as String?;

  Future<void> setDeviceId(String deviceId) async {
    _metadata['deviceId'] = deviceId;
    await _saveMetadata();
  }

  String? getDeviceName() => _metadata['deviceName'] as String?;

  Future<void> setDeviceName(String name) async {
    _metadata['deviceName'] = name;
    await _saveMetadata();
  }

  int getLastSyncCursor() => (_metadata['lastSyncCursor'] as num?)?.toInt() ?? 0;

  Future<void> setLastSyncCursor(int cursor) async {
    _metadata['lastSyncCursor'] = cursor;
    await _saveMetadata();
  }

  DateTime? getLastSyncTime() {
    final str = _metadata['lastSyncTime'] as String?;
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<void> setLastSyncTime(DateTime time) async {
    _metadata['lastSyncTime'] = time.toIso8601String();
    await _saveMetadata();
  }

  // --- Outbox Queue ---

  List<SyncChangeItem> getOutboxItems() => List.unmodifiable(_outbox);

  int get outboxCount => _outbox.length;

  Future<void> enqueueOutboxChange(SyncChangeItem change) async {
    // Deduplicate if clientChangeId already queued
    _outbox.removeWhere((e) => e.clientChangeId == change.clientChangeId);
    _outbox.add(change);
    await _saveOutbox();
  }

  Future<void> removeOutboxItems(List<String> clientChangeIds) async {
    _outbox.removeWhere((e) => clientChangeIds.contains(e.clientChangeId));
    await _saveOutbox();
  }

  Future<void> clearOutbox() async {
    _outbox.clear();
    await _saveOutbox();
  }

  // --- Conflicts ---

  List<SyncConflictItem> getConflicts() => List.unmodifiable(_conflicts);

  Future<void> addConflict(SyncConflictItem conflict) async {
    _conflicts.removeWhere((c) => c.clientChangeId == conflict.clientChangeId);
    _conflicts.add(conflict);
    await _saveConflicts();
  }

  Future<void> markConflictResolved(String clientChangeId) async {
    final idx = _conflicts.indexWhere((c) => c.clientChangeId == clientChangeId);
    if (idx != -1) {
      _conflicts[idx] = _conflicts[idx].copyWith(isResolved: true);
      await _saveConflicts();
    }
  }

  Future<void> removeConflict(String clientChangeId) async {
    _conflicts.removeWhere((c) => c.clientChangeId == clientChangeId);
    await _saveConflicts();
  }

  // --- Downloads ---

  Map<String, DownloadTask> getAllDownloads() => Map.unmodifiable(_downloads);

  DownloadTask? getDownload(String fileId) => _downloads[fileId];

  Future<void> saveDownload(DownloadTask task) async {
    _downloads[task.fileId] = task;
    await _saveDownloads();
  }

  Future<void> removeDownload(String fileId) async {
    _downloads.remove(fileId);
    await _saveDownloads();
  }

  Future<void> clearAllDownloads() async {
    _downloads.clear();
    await _saveDownloads();
  }

  // --- Offline Entity Store (bookmarks, positions, notes) ---

  void saveOfflineEntity(String key, Map<String, dynamic> data) {
    _offlineEntities[key] = data;
  }

  Map<String, dynamic>? getOfflineEntity(String key) => _offlineEntities[key];
}

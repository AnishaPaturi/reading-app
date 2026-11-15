import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/reading_progress.dart';
import 'reading_progress_api.dart';

abstract class ReadingProgressRepository {
  Future<ReadingProgress?> getProgress(String bookFileId);
  Future<ReadingProgress> saveProgress(
    String bookFileId,
    ReadingProgress progress, {
    bool syncRemote = true,
  });
  Future<void> resetProgress(String bookFileId);
  Future<List<ReadingProgress>> getAllProgress();
  Future<void> syncPendingRecords();
  Future<bool> hasPendingSync(String bookFileId);
}

class DefaultReadingProgressRepository implements ReadingProgressRepository {
  final ReadingProgressApi _api;
  static const String _keyPrefix = 'sanctuary_progress_';
  static const String _pendingSyncKey = 'sanctuary_pending_progress_sync';

  DefaultReadingProgressRepository({required ReadingProgressApi api})
      : _api = api;

  @override
  Future<ReadingProgress?> getProgress(String bookFileId) async {
    final local = await getLocalProgress(bookFileId);
    final isPending = await hasPendingSync(bookFileId);

    // If local has un-synced changes, prefer local
    if (isPending && local != null) {
      return local;
    }

    try {
      final remote = await _api.getProgress(bookFileId);
      if (remote != null) {
        // If remote is newer or local doesn't exist, save local cache
        if (local == null ||
            (remote.updatedAt != null &&
                (local.updatedAt == null || remote.updatedAt!.isAfter(local.updatedAt!)))) {
          await _saveLocalOnly(bookFileId, remote);
          return remote;
        }
      }
    } catch (e) {
      debugPrint('ReadingProgressRepository: remote getProgress failed ($e). Using local cache.');
    }

    return local;
  }

  @override
  Future<ReadingProgress> saveProgress(
    String bookFileId,
    ReadingProgress progress, {
    bool syncRemote = true,
  }) async {
    final progressWithTimestamp = progress.copyWith(
      bookFileId: bookFileId,
      updatedAt: DateTime.now(),
      lastOpenedAt: DateTime.now(),
    );

    // 1. Save locally immediately
    await _saveLocalOnly(bookFileId, progressWithTimestamp);

    // 2. Mark pending sync
    await _markPendingSync(bookFileId);

    // 3. Attempt sync if requested
    if (syncRemote) {
      try {
        final synced = await _api.saveProgress(bookFileId, progressWithTimestamp);
        await _saveLocalOnly(bookFileId, synced);
        await _clearPendingSync(bookFileId);
        return synced;
      } catch (e) {
        debugPrint('ReadingProgressRepository: remote sync failed ($e). Queued offline.');
      }
    }

    return progressWithTimestamp;
  }

  @override
  Future<void> resetProgress(String bookFileId) async {
    // 1. Remove local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$bookFileId');

    // 2. Clear remote
    try {
      await _api.resetProgress(bookFileId);
      await _clearPendingSync(bookFileId);
    } catch (e) {
      debugPrint('ReadingProgressRepository: remote reset failed ($e).');
      await _markPendingSync(bookFileId);
    }
  }

  @override
  Future<List<ReadingProgress>> getAllProgress() async {
    final localList = await _getAllLocal();
    final localMap = {for (var p in localList) p.bookFileId: p};
    final pendingIds = await _getPendingSyncIds();

    try {
      final remoteList = await _api.getAllProgress();
      final resultMap = <String, ReadingProgress>{};

      for (final remote in remoteList) {
        if (remote.bookFileId.isEmpty) continue;
        final local = localMap[remote.bookFileId];
        final isPending = pendingIds.contains(remote.bookFileId);

        if (local != null &&
            (isPending ||
                (local.updatedAt != null &&
                    remote.updatedAt != null &&
                    local.updatedAt!.isAfter(remote.updatedAt!)))) {
          resultMap[remote.bookFileId] = local;
        } else {
          resultMap[remote.bookFileId] = remote;
          await _saveLocalOnly(remote.bookFileId, remote);
        }
      }

      // Add any local-only records that were not returned by remote
      for (final local in localList) {
        if (!resultMap.containsKey(local.bookFileId)) {
          resultMap[local.bookFileId] = local;
        }
      }

      if (resultMap.isNotEmpty) {
        return resultMap.values.toList();
      }
    } catch (e) {
      debugPrint('ReadingProgressRepository.getAllProgress remote failed: $e');
    }

    // Fallback to local
    return _getAllLocal();
  }

  @override
  Future<void> syncPendingRecords() async {
    final pendingIds = await _getPendingSyncIds();
    for (final bookFileId in pendingIds) {
      final local = await getLocalProgress(bookFileId);
      if (local != null) {
        try {
          final synced = await _api.saveProgress(bookFileId, local);
          await _saveLocalOnly(bookFileId, synced);
          await _clearPendingSync(bookFileId);
        } catch (e) {
          debugPrint('Sync pending record failed for $bookFileId: $e');
        }
      } else {
        // Was reset offline
        try {
          await _api.resetProgress(bookFileId);
          await _clearPendingSync(bookFileId);
        } catch (_) {}
      }
    }
  }

  @override
  Future<bool> hasPendingSync(String bookFileId) async {
    final pending = await _getPendingSyncIds();
    return pending.contains(bookFileId);
  }

  Future<ReadingProgress?> getLocalProgress(String bookFileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$_keyPrefix$bookFileId');
      if (str != null && str.isNotEmpty) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        map['bookFileId'] = bookFileId;
        return ReadingProgress.fromJson(map);
      }
    } catch (e) {
      debugPrint('Error reading local progress for $bookFileId: $e');
    }
    return null;
  }

  Future<void> _saveLocalOnly(String bookFileId, ReadingProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = progress.toJson();
      map['bookFileId'] = bookFileId;
      if (progress.lastOpenedAt != null) {
        map['lastOpenedAt'] = progress.lastOpenedAt!.toIso8601String();
      }
      if (progress.updatedAt != null) {
        map['updatedAt'] = progress.updatedAt!.toIso8601String();
      }
      await prefs.setString('$_keyPrefix$bookFileId', jsonEncode(map));
    } catch (e) {
      debugPrint('Error saving local progress for $bookFileId: $e');
    }
  }

  Future<List<String>> _getPendingSyncIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_pendingSyncKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _markPendingSync(String bookFileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingSyncKey) ?? [];
      if (!list.contains(bookFileId)) {
        list.add(bookFileId);
        await prefs.setStringList(_pendingSyncKey, list);
      }
    } catch (_) {}
  }

  Future<void> _clearPendingSync(String bookFileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pendingSyncKey) ?? [];
      if (list.contains(bookFileId)) {
        list.remove(bookFileId);
        await prefs.setStringList(_pendingSyncKey, list);
      }
    } catch (_) {}
  }

  Future<List<ReadingProgress>> _getAllLocal() async {
    final list = <ReadingProgress>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
      for (final k in keys) {
        final str = prefs.getString(k);
        if (str != null) {
          final fileId = k.replaceFirst(_keyPrefix, '');
          final map = jsonDecode(str) as Map<String, dynamic>;
          map['bookFileId'] = fileId;
          list.add(ReadingProgress.fromJson(map));
        }
      }
    } catch (_) {}
    return list;
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../domain/annotation_type.dart';
import '../domain/book_annotation.dart';
import 'annotation_api.dart';

abstract class AnnotationRepository {
  Future<List<BookAnnotation>> getAnnotations(String bookFileId);
  Future<BookAnnotation> saveAnnotation(BookAnnotation annotation);
  Future<BookAnnotation> updateAnnotation(String id, String bookFileId, {String? noteText, String? color});
  Future<void> deleteAnnotation(String id, String bookFileId);
  Future<void> syncPendingAnnotations();
}

class DefaultAnnotationRepository implements AnnotationRepository {
  final AnnotationApi _api;
  static const String _keyPrefix = 'sanctuary_annotations_';
  static const String _pendingSyncKey = 'sanctuary_pending_annotations_queue';

  DefaultAnnotationRepository({required AnnotationApi api}) : _api = api;

  @override
  Future<List<BookAnnotation>> getAnnotations(String bookFileId) async {
    final local = await _getLocalAnnotations(bookFileId);
    final localMap = {for (final a in local) a.id: a};

    try {
      final remoteList = await _api.getAnnotationsByBookFile(bookFileId);
      final resultMap = <String, BookAnnotation>{};

      for (final remote in remoteList) {
        final localItem = localMap[remote.id];
        // If local has pending unsynced changes or is marked deleted locally, keep local
        if (localItem != null && (localItem.isPendingSync || localItem.isDeletedLocally)) {
          if (!localItem.isDeletedLocally) {
            resultMap[localItem.id] = localItem;
          }
        } else {
          resultMap[remote.id] = remote;
        }
      }

      // Add any local-only records that haven't been uploaded to remote yet
      for (final localItem in local) {
        if (!resultMap.containsKey(localItem.id) && !localItem.isDeletedLocally) {
          resultMap[localItem.id] = localItem;
        }
      }

      final mergedList = resultMap.values.toList();
      await _saveLocalList(bookFileId, mergedList);
      return mergedList;
    } catch (e) {
      debugPrint('AnnotationRepository.getAnnotations remote error ($e). Using local cache.');
    }

    return local.where((a) => !a.isDeletedLocally).toList();
  }

  @override
  Future<BookAnnotation> saveAnnotation(BookAnnotation annotation) async {
    final id = annotation.id.isEmpty ? const Uuid().v4() : annotation.id;
    final now = DateTime.now();
    final toSave = annotation.copyWith(
      id: id,
      createdAt: annotation.createdAt,
      updatedAt: now,
      isPendingSync: true,
    );

    // 1. Save locally immediately
    final localList = await _getLocalAnnotations(toSave.bookFileId);
    localList.removeWhere((a) => a.id == toSave.id);
    localList.add(toSave);
    await _saveLocalList(toSave.bookFileId, localList);
    await _markPending(toSave.id, toSave.bookFileId, 'CREATE');

    // 2. Try remote sync
    try {
      final remote = await _api.createAnnotation(toSave);
      localList.removeWhere((a) => a.id == toSave.id);
      localList.add(remote);
      await _saveLocalList(toSave.bookFileId, localList);
      await _clearPending(toSave.id);
      return remote;
    } catch (e) {
      debugPrint('AnnotationRepository.saveAnnotation remote failed ($e). Queued offline.');
      return toSave;
    }
  }

  @override
  Future<BookAnnotation> updateAnnotation(
    String id,
    String bookFileId, {
    String? noteText,
    String? color,
  }) async {
    final localList = await _getLocalAnnotations(bookFileId);
    final index = localList.indexWhere((a) => a.id == id);
    if (index == -1) {
      throw Exception('Annotation not found: $id');
    }

    final current = localList[index];
    final updatedLocal = current.copyWith(
      noteText: noteText ?? current.noteText,
      color: color ?? current.color,
      updatedAt: DateTime.now(),
      isPendingSync: true,
    );

    localList[index] = updatedLocal;
    await _saveLocalList(bookFileId, localList);
    await _markPending(id, bookFileId, 'UPDATE');

    try {
      final remote = await _api.updateAnnotation(id, noteText: noteText, color: color);
      localList[index] = remote;
      await _saveLocalList(bookFileId, localList);
      await _clearPending(id);
      return remote;
    } catch (e) {
      debugPrint('AnnotationRepository.updateAnnotation remote failed ($e). Queued offline.');
      return updatedLocal;
    }
  }

  @override
  Future<void> deleteAnnotation(String id, String bookFileId) async {
    final localList = await _getLocalAnnotations(bookFileId);
    final index = localList.indexWhere((a) => a.id == id);

    if (index != -1) {
      final existing = localList[index];
      if (existing.isPendingSync) {
        // Was only created locally and never reached server
        localList.removeAt(index);
        await _clearPending(id);
      } else {
        // Mark deleted locally
        localList[index] = existing.copyWith(isDeletedLocally: true, isPendingSync: true);
        await _markPending(id, bookFileId, 'DELETE');
      }
      await _saveLocalList(bookFileId, localList);
    }

    try {
      await _api.deleteAnnotation(id);
      localList.removeWhere((a) => a.id == id);
      await _saveLocalList(bookFileId, localList);
      await _clearPending(id);
    } catch (e) {
      debugPrint('AnnotationRepository.deleteAnnotation remote failed ($e). Queued offline deletion.');
    }
  }

  @override
  Future<void> syncPendingAnnotations() async {
    final queue = await _getPendingQueue();
    for (final item in queue) {
      final id = item['id']?.toString() ?? '';
      final fileId = item['bookFileId']?.toString() ?? '';
      final action = item['action']?.toString() ?? '';

      if (id.isEmpty || fileId.isEmpty) continue;

      final localList = await _getLocalAnnotations(fileId);
      final annotation = localList.firstWhere(
        (a) => a.id == id,
        orElse: () => BookAnnotation(
          id: id,
          bookId: '',
          bookFileId: fileId,
          type: AnnotationTypeX.fromString(''),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      try {
        if (action == 'CREATE') {
          final synced = await _api.createAnnotation(annotation);
          localList.removeWhere((a) => a.id == id);
          localList.add(synced);
          await _saveLocalList(fileId, localList);
          await _clearPending(id);
        } else if (action == 'UPDATE') {
          final synced = await _api.updateAnnotation(
            id,
            noteText: annotation.noteText,
            color: annotation.color,
          );
          localList.removeWhere((a) => a.id == id);
          localList.add(synced);
          await _saveLocalList(fileId, localList);
          await _clearPending(id);
        } else if (action == 'DELETE') {
          await _api.deleteAnnotation(id);
          localList.removeWhere((a) => a.id == id);
          await _saveLocalList(fileId, localList);
          await _clearPending(id);
        }
      } catch (e) {
        debugPrint('Sync pending annotation failed for $id ($action): $e');
      }
    }
  }

  Future<List<BookAnnotation>> _getLocalAnnotations(String bookFileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString('$_keyPrefix$bookFileId');
      if (str != null && str.isNotEmpty) {
        final list = jsonDecode(str) as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map((j) => BookAnnotation.fromJson(j))
            .toList();
      }
    } catch (e) {
      debugPrint('Error reading local annotations for $bookFileId: $e');
    }
    return [];
  }

  Future<void> _saveLocalList(String bookFileId, List<BookAnnotation> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = list.map((a) => a.toJson()).toList();
      await prefs.setString('$_keyPrefix$bookFileId', jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving local annotations for $bookFileId: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getPendingQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_pendingSyncKey);
      if (str != null && str.isNotEmpty) {
        return List<Map<String, dynamic>>.from(jsonDecode(str));
      }
    } catch (_) {}
    return [];
  }

  Future<void> _markPending(String id, String bookFileId, String action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getPendingQueue();
      queue.removeWhere((item) => item['id'] == id);
      queue.add({
        'id': id,
        'bookFileId': bookFileId,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await prefs.setString(_pendingSyncKey, jsonEncode(queue));
    } catch (_) {}
  }

  Future<void> _clearPending(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await _getPendingQueue();
      queue.removeWhere((item) => item['id'] == id);
      await prefs.setString(_pendingSyncKey, jsonEncode(queue));
    } catch (_) {}
  }
}

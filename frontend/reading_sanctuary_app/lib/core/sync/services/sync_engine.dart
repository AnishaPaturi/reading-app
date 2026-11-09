import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sync_models.dart';
import 'local_storage_db.dart';
import 'sync_api_service.dart';

class SyncEngine extends ChangeNotifier {
  final LocalStorageDb localDb;
  final SyncApiService syncApi;
  final String devicePlatform;

  SyncStatus _status = SyncStatus.synced;
  String? _lastErrorMessage;
  bool _isSyncing = false;
  Timer? _autoSyncTimer;

  SyncStatus get status => _status;
  String? get lastErrorMessage => _lastErrorMessage;
  bool get isSyncing => _isSyncing;
  int get pendingCount => localDb.outboxCount;
  List<SyncConflictItem> get activeConflicts =>
      localDb.getConflicts().where((c) => !c.isResolved).toList();

  SyncEngine({
    required this.localDb,
    required this.syncApi,
    String? platform,
  }) : devicePlatform = platform ?? _resolvePlatform();

  static String _resolvePlatform() {
    if (kIsWeb) return 'WEB';
    if (defaultTargetPlatform == TargetPlatform.android) return 'ANDROID';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'IOS';
    if (defaultTargetPlatform == TargetPlatform.windows) return 'WINDOWS';
    if (defaultTargetPlatform == TargetPlatform.macOS) return 'MACOS';
    return 'UNKNOWN';
  }

  Future<void> init() async {
    await localDb.init();
    if (localDb.outboxCount > 0) {
      _status = SyncStatus.pendingChanges;
    } else {
      _status = SyncStatus.synced;
    }
    notifyListeners();
  }

  String generateChangeId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(999999);
    return 'c_$timestamp\_$rand';
  }

  Future<String> ensureDeviceId() async {
    String? deviceId = localDb.getDeviceId();
    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    String deviceName = localDb.getDeviceName() ?? '$devicePlatform Device ${Random().nextInt(9000) + 1000}';
    try {
      final registered = await syncApi.registerDevice(
        deviceName: deviceName,
        platform: devicePlatform,
      );
      deviceId = registered.id;
      await localDb.setDeviceId(deviceId);
      await localDb.setDeviceName(registered.deviceName);
      return deviceId;
    } catch (e) {
      debugPrint('SyncEngine device registration failed, generating fallback local ID: $e');
      final fallbackId = 'dev_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      await localDb.setDeviceId(fallbackId);
      await localDb.setDeviceName(deviceName);
      return fallbackId;
    }
  }

  Future<void> enqueueChange({
    required String entityType,
    required String entityId,
    required String operation,
    int version = 1,
    int baseVersion = 0,
    required dynamic payload,
  }) async {
    final clientChangeId = generateChangeId();
    final payloadStr = payload is String ? payload : jsonEncode(payload);

    final item = SyncChangeItem(
      clientChangeId: clientChangeId,
      entityType: entityType,
      entityId: entityId,
      operation: operation,
      version: version,
      baseVersion: baseVersion,
      payload: payloadStr,
      changedAt: DateTime.now(),
    );

    await localDb.enqueueOutboxChange(item);

    if (_status != SyncStatus.syncing) {
      _status = SyncStatus.pendingChanges;
      notifyListeners();
    }
  }

  Future<bool> syncNow() async {
    if (_isSyncing) return false;
    _isSyncing = true;
    _status = SyncStatus.syncing;
    _lastErrorMessage = null;
    notifyListeners();

    try {
      final token = syncApi.tokenProvider();
      if (token == null || token.isEmpty) {
        // In offline or guest state
        _status = localDb.outboxCount > 0 ? SyncStatus.pendingChanges : SyncStatus.offline;
        _isSyncing = false;
        notifyListeners();
        return false;
      }

      final deviceId = await ensureDeviceId();

      // 1. Push pending changes
      final outbox = localDb.getOutboxItems();
      if (outbox.isNotEmpty) {
        final pushResult = await syncApi.push(
          deviceId: deviceId,
          changes: outbox,
        );

        if (pushResult.accepted.isNotEmpty) {
          await localDb.removeOutboxItems(pushResult.accepted);
        }

        for (final conflict in pushResult.conflicts) {
          final original = outbox.firstWhere(
            (o) => o.clientChangeId == conflict.clientChangeId,
            orElse: () => outbox.first,
          );
          final fullConflict = SyncConflictItem(
            clientChangeId: conflict.clientChangeId,
            entityType: conflict.entityType,
            entityId: conflict.entityId,
            reason: conflict.reason,
            serverVersion: conflict.serverVersion,
            serverPayload: conflict.serverPayload,
            localPayload: original.payload,
            message: conflict.message,
          );
          await localDb.addConflict(fullConflict);
          await localDb.removeOutboxItems([conflict.clientChangeId]);
        }
      }

      // 2. Pull remote changes
      int cursor = localDb.getLastSyncCursor();
      bool hasMore = true;

      while (hasMore) {
        final pullResult = await syncApi.pull(
          deviceId: deviceId,
          cursor: cursor,
          limit: 100,
        );

        for (final change in pullResult.changes) {
          // Apply change to local entity cache
          localDb.saveOfflineEntity('${change.entityType}:${change.entityId}', {
            'operation': change.operation,
            'version': change.version,
            'payload': change.payload,
            'changedAt': change.changedAt.toIso8601String(),
          });
        }

        cursor = pullResult.nextCursor;
        hasMore = pullResult.hasMore;
      }

      // 3. Acknowledge server cursor
      if (cursor > localDb.getLastSyncCursor()) {
        try {
          await syncApi.acknowledge(deviceId: deviceId, cursor: cursor);
        } catch (e) {
          debugPrint('Cursor acknowledgment warning: $e');
        }
        await localDb.setLastSyncCursor(cursor);
      }

      await localDb.setLastSyncTime(DateTime.now());

      if (localDb.outboxCount > 0) {
        _status = SyncStatus.pendingChanges;
      } else {
        _status = SyncStatus.synced;
      }
      _isSyncing = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('SyncEngine syncNow error: $e');
      _lastErrorMessage = e.toString();
      _status = localDb.outboxCount > 0 ? SyncStatus.pendingChanges : SyncStatus.error;
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> resolveConflict(String clientChangeId, ConflictResolution resolution) async {
    final conflict = localDb.getConflicts().firstWhere((c) => c.clientChangeId == clientChangeId);

    switch (resolution) {
      case ConflictResolution.keepLocal:
        // Re-enqueue local payload with baseVersion set to server's version
        if (conflict.localPayload != null) {
          await enqueueChange(
            entityType: conflict.entityType,
            entityId: conflict.entityId,
            operation: 'UPDATE',
            version: conflict.serverVersion + 1,
            baseVersion: conflict.serverVersion,
            payload: conflict.localPayload!,
          );
        }
        await localDb.markConflictResolved(clientChangeId);
        break;

      case ConflictResolution.keepServer:
        // Discard local edits
        await localDb.markConflictResolved(clientChangeId);
        break;

      case ConflictResolution.keepBoth:
        // Create duplicate with note
        if (conflict.localPayload != null) {
          final map = jsonDecode(conflict.localPayload!) as Map<String, dynamic>;
          final currentTitle = map['title']?.toString() ?? 'Note';
          map['title'] = '$currentTitle (Conflicting copy)';
          await enqueueChange(
            entityType: conflict.entityType,
            entityId: '${conflict.entityId}_copy',
            operation: 'CREATE',
            version: 1,
            baseVersion: 0,
            payload: map,
          );
        }
        await localDb.markConflictResolved(clientChangeId);
        break;
    }

    notifyListeners();
    // Trigger sync to upload resolution
    unawaited(syncNow());
  }

  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) => syncNow());
  }

  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}

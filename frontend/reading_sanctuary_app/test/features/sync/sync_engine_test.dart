import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/sync/models/sync_models.dart';
import 'package:reading_sanctuary_app/core/sync/services/local_storage_db.dart';
import 'package:reading_sanctuary_app/core/sync/services/sync_api_service.dart';
import 'package:reading_sanctuary_app/core/sync/services/sync_engine.dart';

class FakeSyncApiService extends SyncApiService {
  int pushCalls = 0;
  int pullCalls = 0;
  int ackCalls = 0;
  List<SyncChangeItem> lastPushedChanges = [];
  List<SyncChangeItem> pullChangesToReturn = [];
  List<SyncConflictItem> conflictsToReturn = [];

  FakeSyncApiService() : super(tokenProvider: () => 'mock-jwt-token');

  @override
  Future<SyncDeviceModel> registerDevice({
    required String deviceName,
    required String platform,
  }) async {
    return SyncDeviceModel(
      id: 'mock-registered-device-id',
      deviceName: deviceName,
      platform: platform,
    );
  }

  @override
  Future<PushResult> push({
    required String deviceId,
    required List<SyncChangeItem> changes,
  }) async {
    pushCalls++;
    lastPushedChanges = List.from(changes);
    final accepted = changes
        .where((c) => !conflictsToReturn.any((cf) => cf.clientChangeId == c.clientChangeId))
        .map((c) => c.clientChangeId)
        .toList();

    return PushResult(
      accepted: accepted,
      conflicts: conflictsToReturn,
      rejected: [],
      serverCursor: 50,
    );
  }

  @override
  Future<PullResult> pull({
    required String deviceId,
    required int cursor,
    int? limit,
  }) async {
    pullCalls++;
    return PullResult(
      nextCursor: cursor + pullChangesToReturn.length,
      hasMore: false,
      changes: pullChangesToReturn,
    );
  }

  @override
  Future<void> acknowledge({
    required String deviceId,
    required int cursor,
  }) async {
    ackCalls++;
  }
}

void main() {
  late Directory tempDir;
  late LocalStorageDb db;
  late FakeSyncApiService fakeApi;
  late SyncEngine engine;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sync_engine_test_');
    db = LocalStorageDb(customDirectoryPath: tempDir.path);
    await db.init();
    fakeApi = FakeSyncApiService();
    engine = SyncEngine(localDb: db, syncApi: fakeApi, platform: 'ANDROID');
    await engine.init();
  });

  tearDown(() async {
    engine.dispose();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('Auto registers device on first sync', () async {
    expect(db.getDeviceId(), isNull);

    final deviceId = await engine.ensureDeviceId();
    expect(deviceId, 'mock-registered-device-id');
    expect(db.getDeviceId(), 'mock-registered-device-id');
  });

  test('Enqueueing changes transitions status to pendingChanges', () async {
    expect(engine.status, SyncStatus.synced);

    await engine.enqueueChange(
      entityType: 'BOOKMARK',
      entityId: 'bm-1',
      operation: 'CREATE',
      payload: {'page': 10},
    );

    expect(engine.status, SyncStatus.pendingChanges);
    expect(engine.pendingCount, 1);
  });

  test('syncNow pushes outbox items and marks synced', () async {
    await engine.enqueueChange(
      entityType: 'BOOK_NOTE',
      entityId: 'note-1',
      operation: 'CREATE',
      payload: {'title': 'My Note'},
    );

    final success = await engine.syncNow();
    expect(success, isTrue);
    expect(fakeApi.pushCalls, 1);
    expect(fakeApi.lastPushedChanges.length, 1);
    expect(engine.pendingCount, 0);
    expect(engine.status, SyncStatus.synced);
  });

  test('syncNow captures conflicts and allows resolution', () async {
    await engine.enqueueChange(
      entityType: 'BOOK_NOTE',
      entityId: 'note-conflict',
      operation: 'UPDATE',
      payload: {'title': 'Offline edit'},
    );

    final queuedId = db.getOutboxItems().first.clientChangeId;
    fakeApi.conflictsToReturn = [
      SyncConflictItem(
        clientChangeId: queuedId,
        entityType: 'BOOK_NOTE',
        entityId: 'note-conflict',
        reason: 'VERSION_CONFLICT',
        serverVersion: 3,
        serverPayload: '{"title":"Server edit"}',
        message: 'Conflict',
      ),
    ];

    await engine.syncNow();

    expect(engine.activeConflicts.length, 1);
    expect(engine.activeConflicts.first.clientChangeId, queuedId);

    // Resolve conflict by keeping local changes
    await engine.resolveConflict(queuedId, ConflictResolution.keepLocal);
    expect(engine.activeConflicts.isEmpty, isTrue);
  });
}

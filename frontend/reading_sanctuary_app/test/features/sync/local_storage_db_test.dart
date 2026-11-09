import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/sync/models/sync_models.dart';
import 'package:reading_sanctuary_app/core/sync/services/local_storage_db.dart';
import 'package:reading_sanctuary_app/features/offline/domain/models/download_task.dart';

void main() {
  late Directory tempDir;
  late LocalStorageDb db;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sanctuary_db_test_');
    db = LocalStorageDb(customDirectoryPath: tempDir.path);
    await db.init();
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('Persists and loads device ID and cursor', () async {
    await db.setDeviceId('test-device-uuid');
    await db.setDeviceName('Pixel 6');
    await db.setLastSyncCursor(77);

    // Create a new instance pointing to same temp dir
    final reloaded = LocalStorageDb(customDirectoryPath: tempDir.path);
    await reloaded.init();

    expect(reloaded.getDeviceId(), 'test-device-uuid');
    expect(reloaded.getDeviceName(), 'Pixel 6');
    expect(reloaded.getLastSyncCursor(), 77);
  });

  test('Outbox queue enqueues, dedupes, and removes processed items', () async {
    final item1 = SyncChangeItem(
      clientChangeId: 'c-1',
      entityType: 'BOOKMARK',
      entityId: 'bm-1',
      operation: 'CREATE',
      payload: '{}',
      changedAt: DateTime.now(),
    );

    final item2 = SyncChangeItem(
      clientChangeId: 'c-2',
      entityType: 'READING_POSITION',
      entityId: 'pos-1',
      operation: 'UPDATE',
      payload: '{"page":10}',
      changedAt: DateTime.now(),
    );

    await db.enqueueOutboxChange(item1);
    await db.enqueueOutboxChange(item2);

    expect(db.outboxCount, 2);

    // Re-queue same clientChangeId updates the item without duplicating
    final item1Updated = SyncChangeItem(
      clientChangeId: 'c-1',
      entityType: 'BOOKMARK',
      entityId: 'bm-1',
      operation: 'UPDATE',
      payload: '{"title":"new"}',
      changedAt: DateTime.now(),
    );
    await db.enqueueOutboxChange(item1Updated);
    expect(db.outboxCount, 2);

    // Remove processed item
    await db.removeOutboxItems(['c-1']);
    expect(db.outboxCount, 1);
    expect(db.getOutboxItems().first.clientChangeId, 'c-2');
  });

  test('Persists downloads and conflicts across sessions', () async {
    const conflict = SyncConflictItem(
      clientChangeId: 'c-conflict-1',
      entityType: 'BOOK_NOTE',
      entityId: 'note-1',
      reason: 'VERSION_CONFLICT',
      serverVersion: 2,
      message: 'Conflict',
    );
    await db.addConflict(conflict);

    final task = DownloadTask(
      fileId: 'f-100',
      bookId: 'b-200',
      bookTitle: 'Clean Architecture',
      fileName: 'clean_arch.pdf',
      format: 'PDF',
      localPath: '${tempDir.path}/clean_arch.pdf',
      status: DownloadStatus.downloaded,
      totalBytes: 5000,
    );
    await db.saveDownload(task);

    final reloaded = LocalStorageDb(customDirectoryPath: tempDir.path);
    await reloaded.init();

    expect(reloaded.getConflicts().length, 1);
    expect(reloaded.getConflicts().first.clientChangeId, 'c-conflict-1');

    final loadedTask = reloaded.getDownload('f-100');
    expect(loadedTask, isNotNull);
    expect(loadedTask!.bookTitle, 'Clean Architecture');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/sync/models/sync_models.dart';

void main() {
  group('SyncDeviceModel serialization', () {
    test('toJson and fromJson preserves all fields', () {
      final now = DateTime.now();
      final model = SyncDeviceModel(
        id: 'dev-123',
        deviceName: 'Pixel 8',
        platform: 'ANDROID',
        lastSyncCursor: 42,
        lastSeenAt: now,
        isActive: true,
        createdAt: now,
      );

      final json = model.toJson();
      final restored = SyncDeviceModel.fromJson(json);

      expect(restored.id, 'dev-123');
      expect(restored.deviceName, 'Pixel 8');
      expect(restored.platform, 'ANDROID');
      expect(restored.lastSyncCursor, 42);
      expect(restored.isActive, isTrue);
    });
  });

  group('SyncChangeItem serialization', () {
    test('toJson and fromJson preserves all fields', () {
      final now = DateTime.now();
      const item = SyncChangeItem(
        cursor: 10,
        clientChangeId: 'c-abc',
        entityType: 'BOOKMARK',
        entityId: 'bm-99',
        operation: 'CREATE',
        version: 1,
        baseVersion: 0,
        payload: '{"page":5}',
        changedAt: null ?? DateTime(2026, 11, 9),
      );

      final json = item.toJson();
      final restored = SyncChangeItem.fromJson(json);

      expect(restored.cursor, 10);
      expect(restored.clientChangeId, 'c-abc');
      expect(restored.entityType, 'BOOKMARK');
      expect(restored.entityId, 'bm-99');
      expect(restored.operation, 'CREATE');
      expect(restored.payload, '{"page":5}');
    });
  });

  group('SyncConflictItem serialization', () {
    test('toJson and fromJson with copyWith', () {
      const conflict = SyncConflictItem(
        clientChangeId: 'c-conflict-1',
        entityType: 'BOOK_NOTE',
        entityId: 'note-45',
        reason: 'VERSION_CONFLICT',
        serverVersion: 3,
        serverPayload: '{"title":"Server note"}',
        localPayload: '{"title":"Local note"}',
        message: 'Conflict on note',
        isResolved: false,
      );

      final json = conflict.toJson();
      final restored = SyncConflictItem.fromJson(json);

      expect(restored.clientChangeId, 'c-conflict-1');
      expect(restored.reason, 'VERSION_CONFLICT');
      expect(restored.serverVersion, 3);
      expect(restored.isResolved, isFalse);

      final resolved = restored.copyWith(isResolved: true);
      expect(resolved.isResolved, isTrue);
    });
  });
}

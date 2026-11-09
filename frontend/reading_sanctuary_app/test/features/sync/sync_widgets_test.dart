import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/sync/models/sync_models.dart';
import 'package:reading_sanctuary_app/core/sync/presentation/widgets/sync_conflict_card.dart';
import 'package:reading_sanctuary_app/core/sync/presentation/widgets/sync_status_indicator.dart';
import 'package:reading_sanctuary_app/core/sync/providers/sync_providers.dart';
import 'package:reading_sanctuary_app/features/offline/domain/models/download_task.dart';
import 'package:reading_sanctuary_app/features/offline/presentation/widgets/offline_download_button.dart';

void main() {
  testWidgets('SyncStatusIndicator displays cloud done when synced', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncStatusProvider.overrideWithValue(SyncStatus.synced),
          pendingSyncCountProvider.overrideWithValue(0),
          syncConflictsProvider.overrideWithValue([]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
  });

  testWidgets('SyncStatusIndicator displays pending changes badge', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncStatusProvider.overrideWithValue(SyncStatus.pendingChanges),
          pendingSyncCountProvider.overrideWithValue(3),
          syncConflictsProvider.overrideWithValue([]),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(),
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
  });

  testWidgets('OfflineDownloadButton shows Download for Offline when not downloaded', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fileDownloadTaskProvider('test-file-id').overrideWithValue(null),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OfflineDownloadButton(
              bookId: 'b-1',
              fileId: 'test-file-id',
              bookTitle: 'Test Title',
              fileName: 'test.pdf',
              format: 'PDF',
            ),
          ),
        ),
      ),
    );

    expect(find.text('Download for Offline'), findsOneWidget);
  });

  testWidgets('OfflineDownloadButton shows Offline Ready when completed', (tester) async {
    const task = DownloadTask(
      fileId: 'test-file-id',
      bookId: 'b-1',
      bookTitle: 'Test Title',
      fileName: 'test.pdf',
      format: 'PDF',
      localPath: '/tmp/test.pdf',
      status: DownloadStatus.downloaded,
      totalBytes: 2048000,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fileDownloadTaskProvider('test-file-id').overrideWithValue(task),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: OfflineDownloadButton(
              bookId: 'b-1',
              fileId: 'test-file-id',
              bookTitle: 'Test Title',
              fileName: 'test.pdf',
              format: 'PDF',
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Offline Ready'), findsOneWidget);
  });

  testWidgets('SyncConflictCard renders conflict details and resolution buttons', (tester) async {
    const conflict = SyncConflictItem(
      clientChangeId: 'c-test',
      entityType: 'BOOK_NOTE',
      entityId: 'note-1',
      reason: 'VERSION_CONFLICT',
      serverVersion: 4,
      serverPayload: '{"title":"Server Title"}',
      localPayload: '{"title":"Local Title"}',
      message: 'Concurrent note modification',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SyncConflictCard(conflict: conflict),
          ),
        ),
      ),
    );

    expect(find.text('Conflict on BOOK_NOTE'), findsOneWidget);
    expect(find.text('VERSION_CONFLICT'), findsOneWidget);
    expect(find.text('Keep My Changes'), findsOneWidget);
    expect(find.text('Keep Server Version'), findsOneWidget);
    expect(find.text('Keep Both'), findsOneWidget);
  });
}

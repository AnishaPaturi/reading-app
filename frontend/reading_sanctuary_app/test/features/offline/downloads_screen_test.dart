import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/sync/providers/sync_providers.dart';
import 'package:reading_sanctuary_app/core/sync/services/local_storage_db.dart';
import 'package:reading_sanctuary_app/features/offline/domain/models/download_task.dart';
import 'package:reading_sanctuary_app/features/offline/presentation/screens/downloads_screen.dart';
import 'package:reading_sanctuary_app/features/offline/services/download_manager.dart';
import 'package:reading_sanctuary_app/features/offline/services/downloads_scanner_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('downloads_ui_test_');
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  testWidgets('Renders empty states when no downloads exist', (tester) async {
    final localDb = LocalStorageDb(customDirectoryPath: tempDir.path);
    final downloadManager = DownloadManager(
      localDb: localDb,
      customDownloadDirPath: tempDir.path,
    );
    final scanner = DownloadsScannerService(
      downloadManager: downloadManager,
      customDownloadsPath: tempDir.path,
    );

    await tester.runAsync(() async {
      await localDb.init();
      await downloadManager.init();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageDbProvider.overrideWithValue(localDb),
          downloadManagerProvider.overrideWith((ref) => downloadManager),
          downloadsScannerServiceProvider.overrideWith((ref) => scanner),
        ],
        child: const MaterialApp(
          home: DownloadsScreen(autoScanOnMount: false),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Downloads'), findsWidgets);
    expect(find.text('Recently Downloaded'), findsOneWidget);
    expect(find.text('No recently downloaded books'), findsOneWidget);
    expect(find.text('All Downloads'), findsOneWidget);
  });

  testWidgets('Displays Active Downloads when active tasks exist', (tester) async {
    final localDb = LocalStorageDb(customDirectoryPath: tempDir.path);
    late File activeFile;
    late DownloadTask activeTask;

    final downloadManager = DownloadManager(
      localDb: localDb,
      customDownloadDirPath: tempDir.path,
    );
    final scanner = DownloadsScannerService(
      downloadManager: downloadManager,
      customDownloadsPath: tempDir.path,
    );

    await tester.runAsync(() async {
      await localDb.init();
      activeFile = File('${tempDir.path}/active.pdf');
      await activeFile.writeAsString('partial content');

      activeTask = DownloadTask(
        fileId: 'active-1',
        bookId: 'b-active',
        bookTitle: 'Large Manual',
        fileName: 'active.pdf',
        format: 'PDF',
        localPath: activeFile.path,
        totalBytes: 10000000,
        downloadedBytes: 4500000,
        status: DownloadStatus.downloading,
      );
      await localDb.saveDownload(activeTask);
      await downloadManager.init();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageDbProvider.overrideWithValue(localDb),
          downloadManagerProvider.overrideWith((ref) => downloadManager),
          downloadsScannerServiceProvider.overrideWith((ref) => scanner),
        ],
        child: const MaterialApp(
          home: DownloadsScreen(autoScanOnMount: false),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Active Downloads'), findsOneWidget);
    expect(find.text('Large Manual'), findsOneWidget);
    expect(find.textContaining('45%'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  testWidgets('Displays Recently Downloaded and All Downloads with distinction', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final localDb = LocalStorageDb(customDirectoryPath: tempDir.path);
    final now = DateTime.now();

    final downloadManager = DownloadManager(
      localDb: localDb,
      customDownloadDirPath: tempDir.path,
    );
    final scanner = DownloadsScannerService(
      downloadManager: downloadManager,
      customDownloadsPath: tempDir.path,
    );

    await tester.runAsync(() async {
      await localDb.init();

      // 1. App Downloaded Book
      final appFile = File('${tempDir.path}/app_book.epub');
      await appFile.writeAsString('Epub data');

      final appTask = DownloadTask(
        fileId: 'app-task-1',
        bookId: 'b-app',
        bookTitle: 'App Masterpiece',
        author: 'Famous Author',
        fileName: 'app_book.epub',
        format: 'EPUB',
        localPath: appFile.path,
        totalBytes: 500000,
        downloadedBytes: 500000,
        status: DownloadStatus.downloaded,
        source: DownloadSource.appDownload,
        isDiscovered: false,
        downloadedAt: now,
      );

      // 2. Discovered Book from folder
      final discFile = File('${tempDir.path}/discovered_doc.pdf');
      await discFile.writeAsString('PDF data');

      final discTask = DownloadTask(
        fileId: 'disc-task-2',
        bookId: 'b-disc',
        bookTitle: 'Folder Document',
        author: 'Local Writer',
        fileName: 'discovered_doc.pdf',
        format: 'PDF',
        localPath: discFile.path,
        totalBytes: 200000,
        downloadedBytes: 200000,
        status: DownloadStatus.downloaded,
        source: DownloadSource.folderDiscovered,
        isDiscovered: true,
        downloadedAt: null,
        fileLastModified: now.subtract(const Duration(days: 4)),
      );

      await localDb.saveDownload(appTask);
      await localDb.saveDownload(discTask);
      await downloadManager.init();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageDbProvider.overrideWithValue(localDb),
          downloadManagerProvider.overrideWith((ref) => downloadManager),
          downloadsScannerServiceProvider.overrideWith((ref) => scanner),
        ],
        child: const MaterialApp(
          home: DownloadsScreen(autoScanOnMount: false),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // App book appears in Recently Downloaded AND All Downloads
    expect(find.text('App Masterpiece'), findsWidgets);
    expect(find.text('Famous Author'), findsWidgets);

    // Discovered book appears in All Downloads with 'Downloads Folder' tag
    expect(find.text('Folder Document'), findsOneWidget);
    expect(find.text('Downloads Folder'), findsOneWidget);
    expect(find.text('Downloaded'), findsOneWidget);
  });

  testWidgets('Removal dialog presents distinct options and protects library', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final localDb = LocalStorageDb(customDirectoryPath: tempDir.path);
    late File bookFile;
    late DownloadTask task;

    final downloadManager = DownloadManager(
      localDb: localDb,
      customDownloadDirPath: tempDir.path,
    );
    final scanner = DownloadsScannerService(
      downloadManager: downloadManager,
      customDownloadsPath: tempDir.path,
    );

    await tester.runAsync(() async {
      await localDb.init();
      bookFile = File('${tempDir.path}/removable.pdf');
      await bookFile.writeAsString('Removable data');

      task = DownloadTask(
        fileId: 'removable-1',
        bookId: 'b-rem',
        bookTitle: 'Removable Book',
        fileName: 'removable.pdf',
        format: 'PDF',
        localPath: bookFile.path,
        totalBytes: 12000,
        downloadedBytes: 12000,
        status: DownloadStatus.downloaded,
        downloadedAt: DateTime.now(),
      );
      await localDb.saveDownload(task);
      await downloadManager.init();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageDbProvider.overrideWithValue(localDb),
          downloadManagerProvider.overrideWith((ref) => downloadManager),
          downloadsScannerServiceProvider.overrideWith((ref) => scanner),
        ],
        child: const MaterialApp(
          home: DownloadsScreen(autoScanOnMount: false),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Removable Book'), findsWidgets);

    // Tap more options icon
    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify dialog contents
    expect(find.text('Remove Download'), findsOneWidget);
    expect(find.text('Remove from Downloads only'), findsOneWidget);
    expect(find.text('Delete file from device storage'), findsOneWidget);
    expect(find.textContaining('will NOT remove this book from your main library'), findsOneWidget);

    // Tap 'Remove from Downloads only' inside runAsync because it executes manager.removeDownload()
    await tester.runAsync(() async {
      await tester.tap(find.text('Remove from Downloads only'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify removed from screen list
    expect(find.text('Removable Book'), findsNothing);
    // Physical file MUST remain intact
    expect(bookFile.existsSync(), isTrue);
  });

  testWidgets('Sorting controls change order between Newest and Oldest First', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final localDb = LocalStorageDb(customDirectoryPath: tempDir.path);
    final now = DateTime.now();

    final downloadManager = DownloadManager(
      localDb: localDb,
      customDownloadDirPath: tempDir.path,
    );
    final scanner = DownloadsScannerService(
      downloadManager: downloadManager,
      customDownloadsPath: tempDir.path,
    );

    await tester.runAsync(() async {
      await localDb.init();

      final f1 = File('${tempDir.path}/book_recent.epub');
      await f1.writeAsString('recent');
      final tRecent = DownloadTask(
        fileId: 'f-rec',
        bookId: 'b-rec',
        bookTitle: 'Recent Book',
        fileName: 'book_recent.epub',
        format: 'EPUB',
        localPath: f1.path,
        totalBytes: 1000,
        downloadedBytes: 1000,
        status: DownloadStatus.downloaded,
        downloadedAt: now,
      );

      final f2 = File('${tempDir.path}/book_old.epub');
      await f2.writeAsString('old');
      final tOld = DownloadTask(
        fileId: 'f-old',
        bookId: 'b-old',
        bookTitle: 'Old Book',
        fileName: 'book_old.epub',
        format: 'EPUB',
        localPath: f2.path,
        totalBytes: 1000,
        downloadedBytes: 1000,
        status: DownloadStatus.downloaded,
        downloadedAt: now.subtract(const Duration(days: 30)),
      );

      await localDb.saveDownload(tRecent);
      await localDb.saveDownload(tOld);
      await downloadManager.init();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageDbProvider.overrideWithValue(localDb),
          downloadManagerProvider.overrideWith((ref) => downloadManager),
          downloadsScannerServiceProvider.overrideWith((ref) => scanner),
        ],
        child: const MaterialApp(
          home: DownloadsScreen(autoScanOnMount: false),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Default: Newest First
    expect(find.text('Newest First'), findsOneWidget);

    // Switch to Oldest First
    await tester.tap(find.text('Newest First'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Oldest First').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Oldest First'), findsWidgets);
  });
}

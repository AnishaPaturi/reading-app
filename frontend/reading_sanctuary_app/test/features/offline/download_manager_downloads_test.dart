import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:reading_sanctuary_app/core/sync/services/local_storage_db.dart';
import 'package:reading_sanctuary_app/features/offline/domain/models/download_task.dart';
import 'package:reading_sanctuary_app/features/offline/services/download_manager.dart';

class MockStreamClient extends http.BaseClient {
  final Uint8List bytes;
  final int statusCode;
  final Duration? chunkDelay;

  MockStreamClient({
    required this.bytes,
    this.statusCode = 200,
    this.chunkDelay,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    Stream<List<int>> stream;
    if (chunkDelay != null) {
      stream = () async* {
        for (var i = 0; i < bytes.length; i += 100) {
          final end = (i + 100 < bytes.length) ? i + 100 : bytes.length;
          yield bytes.sublist(i, end);
          await Future.delayed(chunkDelay!);
        }
      }();
    } else {
      stream = Stream.value(bytes);
    }

    return http.StreamedResponse(
      stream,
      statusCode,
      contentLength: bytes.length,
      request: request,
    );
  }
}

void main() {
  late Directory tempDir;
  late LocalStorageDb localDb;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('download_mgr_tests_');
    localDb = LocalStorageDb(customDirectoryPath: tempDir.path);
    await localDb.init();
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('Tracks active downloads and moves to completed/recently downloaded on finish', () async {
    final bookData = utf8.encode('Sample ebook content for download testing.');
    final client = MockStreamClient(bytes: Uint8List.fromList(bookData));

    final manager = DownloadManager(
      localDb: localDb,
      httpClient: client,
      customDownloadDirPath: tempDir.path,
    );
    await manager.init();

    // Start download
    final downloadFuture = manager.downloadBookFile(
      bookId: 'book-101',
      fileId: 'file-101',
      bookTitle: 'Flutter Architecture',
      author: 'Expert Author',
      fileName: 'flutter_arch.epub',
      format: 'EPUB',
      directDownloadUrl: 'https://example.com/flutter_arch.epub',
    );

    await downloadFuture;

    // Verify it is completed
    expect(manager.isDownloaded('file-101'), isTrue);
    expect(manager.getActiveDownloads(), isEmpty);

    final completed = manager.getCompletedDownloads();
    expect(completed.length, 1);
    expect(completed.first.bookTitle, 'Flutter Architecture');
    expect(completed.first.author, 'Expert Author');
    expect(completed.first.isCompleted, isTrue);

    // Verify it appears in Recently Downloaded
    final recent = manager.getRecentlyDownloadedBooks();
    expect(recent.length, 1);
    expect(recent.first.fileId, 'file-101');
    expect(recent.first.isRecentlyDownloaded, isTrue);
  });

  test('Discovered books do NOT appear in Recently Downloaded (Recently Downloaded ≠ Downloads Folder)', () async {
    final manager = DownloadManager(
      localDb: localDb,
      customDownloadDirPath: tempDir.path,
    );
    await manager.init();

    // Create a physical file on disk
    final discFile = File('${tempDir.path}/discovered_book.epub');
    await discFile.writeAsString('Discovered content on device');

    final discoveredTask = DownloadTask(
      fileId: 'disc-task-1',
      bookId: 'disc-task-1',
      bookTitle: 'Discovered Book',
      fileName: 'discovered_book.epub',
      format: 'EPUB',
      localPath: discFile.path,
      totalBytes: 25,
      downloadedBytes: 25,
      status: DownloadStatus.downloaded,
      source: DownloadSource.folderDiscovered,
      isDiscovered: true,
      downloadedAt: null, // Unknown download date!
      fileLastModified: DateTime.now().subtract(const Duration(days: 5)),
    );

    await manager.registerDiscoveredBooks([discoveredTask]);

    // Check All Downloads contains the discovered book
    final all = manager.getCompletedDownloads();
    expect(all.length, 1);
    expect(all.first.fileId, 'disc-task-1');
    expect(all.first.isDiscovered, isTrue);

    // Check Recently Downloaded does NOT contain the discovered book!
    final recent = manager.getRecentlyDownloadedBooks();
    expect(recent, isEmpty);
  });

  test('Avoids duplicate entries when scanning discovered files matching app downloads', () async {
    final bookData = utf8.encode('Original app downloaded book data');
    final client = MockStreamClient(bytes: Uint8List.fromList(bookData));

    final manager = DownloadManager(
      localDb: localDb,
      httpClient: client,
      customDownloadDirPath: tempDir.path,
    );
    await manager.init();

    await manager.downloadBookFile(
      bookId: 'b-orig',
      fileId: 'f-orig',
      bookTitle: 'Original Book',
      fileName: 'original.pdf',
      format: 'PDF',
      directDownloadUrl: 'https://example.com/orig.pdf',
    );

    final origTask = manager.getTask('f-orig')!;
    expect(origTask.isDiscovered, isFalse);
    expect(origTask.isRecentlyDownloaded, isTrue);

    // Scanner later discovers the same file path in Downloads folder
    final duplicateDiscovered = DownloadTask(
      fileId: 'f-orig',
      bookId: 'b-orig',
      bookTitle: 'Original Book (Discovered)',
      fileName: 'original.pdf',
      format: 'PDF',
      localPath: origTask.localPath,
      totalBytes: bookData.length,
      downloadedBytes: bookData.length,
      status: DownloadStatus.downloaded,
      source: DownloadSource.folderDiscovered,
      isDiscovered: true,
      downloadedAt: null,
    );

    await manager.registerDiscoveredBooks([duplicateDiscovered]);

    // Preserved the original app download task without overwriting or duplicating!
    expect(manager.getCompletedDownloads().length, 1);
    final preservedTask = manager.getTask('f-orig')!;
    expect(preservedTask.isDiscovered, isFalse);
    expect(preservedTask.bookTitle, 'Original Book');
    expect(manager.getRecentlyDownloadedBooks().length, 1);
  });

  test('Downloads ≠ Library: Removal from Downloads only vs Deleting physical file', () async {
    final bookData = utf8.encode('File for deletion test');
    final client = MockStreamClient(bytes: Uint8List.fromList(bookData));

    final manager = DownloadManager(
      localDb: localDb,
      httpClient: client,
      customDownloadDirPath: tempDir.path,
    );
    await manager.init();

    // 1. Download file 1
    await manager.downloadBookFile(
      bookId: 'b-keep',
      fileId: 'f-keep',
      bookTitle: 'Keep File on Disk',
      fileName: 'keep.pdf',
      format: 'PDF',
      directDownloadUrl: 'https://example.com/keep.pdf',
    );

    final pathKeep = manager.getTask('f-keep')!.localPath;
    expect(File(pathKeep).existsSync(), isTrue);

    // Remove from Downloads listing only (deletePhysicalFile: false)
    await manager.removeDownload('f-keep', deletePhysicalFile: false);
    expect(manager.isDownloaded('f-keep'), isFalse);
    expect(manager.getTask('f-keep'), isNull);
    // Physical file MUST still exist on device!
    expect(File(pathKeep).existsSync(), isTrue);

    // 2. Download file 2
    await manager.downloadBookFile(
      bookId: 'b-delete',
      fileId: 'f-delete',
      bookTitle: 'Delete File from Disk',
      fileName: 'delete.pdf',
      format: 'PDF',
      directDownloadUrl: 'https://example.com/delete.pdf',
    );

    final pathDelete = manager.getTask('f-delete')!.localPath;
    expect(File(pathDelete).existsSync(), isTrue);

    // Delete physical file (deletePhysicalFile: true)
    await manager.removeDownload('f-delete', deletePhysicalFile: true);
    expect(manager.isDownloaded('f-delete'), isFalse);
    expect(manager.getTask('f-delete'), isNull);
    // Physical file MUST be deleted from disk!
    expect(File(pathDelete).existsSync(), isFalse);
  });

  test('Pause, Resume, and Cancel downloads', () async {
    final client = MockStreamClient(
      bytes: Uint8List.fromList(utf8.encode('Pausable book content data')),
      chunkDelay: const Duration(milliseconds: 50),
    );
    final manager = DownloadManager(
      localDb: localDb,
      httpClient: client,
      customDownloadDirPath: tempDir.path,
    );
    await manager.init();

    // Start download asynchronously
    unawaited(
      manager.downloadBookFile(
        bookId: 'b-pause',
        fileId: 'f-pause',
        bookTitle: 'Pausable Book',
        fileName: 'pausable.pdf',
        format: 'PDF',
        directDownloadUrl: 'https://example.com/pausable.pdf',
      ),
    );

    // Wait for download task to register under parallel test load
    for (var i = 0; i < 25 && manager.getTask('f-pause') == null; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
    }

    expect(manager.getTask('f-pause'), isNotNull);

    // Pause download
    manager.pauseDownload('f-pause');
    final pausedTask = manager.getTask('f-pause')!;
    expect(pausedTask.isPaused, isTrue);

    // Cancel download
    await manager.cancelDownload('f-pause');
    expect(manager.getTask('f-pause'), isNull);
  });

  test('Preserves download metadata across application restarts and cleans ghost files', () async {
    // Session 1: Download book
    final bookData = utf8.encode('Persistent book content');
    final client = MockStreamClient(bytes: Uint8List.fromList(bookData));

    final manager1 = DownloadManager(
      localDb: localDb,
      httpClient: client,
      customDownloadDirPath: tempDir.path,
    );
    await manager1.init();

    await manager1.downloadBookFile(
      bookId: 'b-persist',
      fileId: 'f-persist',
      bookTitle: 'Persistent Book',
      fileName: 'persist.epub',
      format: 'EPUB',
      directDownloadUrl: 'https://example.com/persist.epub',
    );

    expect(manager1.isDownloaded('f-persist'), isTrue);

    // Session 2: Reload with new DownloadManager and new LocalStorageDb pointing to same directory
    final localDb2 = LocalStorageDb(customDirectoryPath: tempDir.path);
    await localDb2.init();

    final manager2 = DownloadManager(
      localDb: localDb2,
      customDownloadDirPath: tempDir.path,
    );
    await manager2.init();

    expect(manager2.isDownloaded('f-persist'), isTrue);
    final reloadedTask = manager2.getTask('f-persist')!;
    expect(reloadedTask.bookTitle, 'Persistent Book');
    expect(reloadedTask.isRecentlyDownloaded, isTrue);

    // If file is deleted externally outside the app
    final file = File(reloadedTask.localPath);
    await file.delete();

    // Session 3: Reload should detect file is missing and clean up
    final localDb3 = LocalStorageDb(customDirectoryPath: tempDir.path);
    await localDb3.init();
    final manager3 = DownloadManager(
      localDb: localDb3,
      customDownloadDirPath: tempDir.path,
    );
    await manager3.init();

    expect(manager3.isDownloaded('f-persist'), isFalse);
    expect(manager3.getTask('f-persist'), isNull);
  });
}

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/sync/services/local_storage_db.dart';
import 'package:reading_sanctuary_app/features/offline/domain/models/download_task.dart';
import 'package:reading_sanctuary_app/features/offline/services/download_manager.dart';
import 'package:reading_sanctuary_app/features/offline/services/downloads_scanner_service.dart';

void main() {
  late Directory tempDir;
  late Directory downloadsDir;
  late LocalStorageDb localDb;
  late DownloadManager downloadManager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('scanner_test_env_');
    downloadsDir = Directory('${tempDir.path}/Downloads');
    await downloadsDir.create(recursive: true);

    localDb = LocalStorageDb(customDirectoryPath: tempDir.path);
    await localDb.init();

    downloadManager = DownloadManager(
      localDb: localDb,
      customDownloadDirPath: tempDir.path,
    );
    await downloadManager.init();
  });

  tearDown(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('Scans all supported ebook and document formats in Downloads directory', () async {
    // Create supported files
    final epubFile = File('${downloadsDir.path}/Dune.epub');
    await epubFile.writeAsString('Dummy EPUB content');

    final pdfFile = File('${downloadsDir.path}/Clean_Code.pdf');
    await pdfFile.writeAsString('Dummy PDF content');

    final mobiFile = File('${downloadsDir.path}/SciFi.mobi');
    await mobiFile.writeAsString('Dummy MOBI content');

    final azw3File = File('${downloadsDir.path}/Novel.azw3');
    await azw3File.writeAsString('Dummy AZW3 content');

    final fb2File = File('${downloadsDir.path}/Story.fb2');
    await fb2File.writeAsString('Dummy FB2 content');

    final txtFile = File('${downloadsDir.path}/Notes.txt');
    await txtFile.writeAsString('Dummy TXT content');

    final docFile = File('${downloadsDir.path}/Doc1.doc');
    await docFile.writeAsString('Dummy DOC content');

    final docxFile = File('${downloadsDir.path}/Report.docx');
    await docxFile.writeAsString('Dummy DOCX content');

    final rtfFile = File('${downloadsDir.path}/Document.rtf');
    await rtfFile.writeAsString('Dummy RTF content');

    final mp3File = File('${downloadsDir.path}/Chapter1.mp3');
    await mp3File.writeAsString('Dummy MP3 audio');

    // Create unsupported and hidden files (should be ignored)
    final exeFile = File('${downloadsDir.path}/Setup.exe');
    await exeFile.writeAsString('binary');

    final zipFile = File('${downloadsDir.path}/Archive.zip');
    await zipFile.writeAsString('archive');

    final hiddenFile = File('${downloadsDir.path}/.hidden_book.pdf');
    await hiddenFile.writeAsString('hidden');

    final scanner = DownloadsScannerService(
      downloadManager: downloadManager,
      customDownloadsPath: downloadsDir.path,
    );

    final result = await scanner.scanDownloadsFolder();

    expect(result.isSuccess, isTrue);
    expect(result.count, 10); // Exactly the 10 supported formats

    final titles = result.discoveredTasks.map((t) => t.bookTitle).toList();
    expect(titles, contains('Dune'));
    expect(titles, contains('Clean Code')); // Cleaned up underscores
    expect(titles, contains('SciFi'));
    expect(titles, contains('Chapter1'));

    // Check that discovered books have correct properties
    for (final task in result.discoveredTasks) {
      expect(task.isDiscovered, isTrue);
      expect(task.source, DownloadSource.folderDiscovered);
      expect(task.downloadedAt, isNull, reason: 'Must never fabricate download date');
      expect(task.fileLastModified, isNotNull);
      expect(task.isCompleted, isTrue);
      expect(File(task.localPath).existsSync(), isTrue);
    }

    // Verify original files are NOT moved or modified
    expect(await epubFile.exists(), isTrue);
    expect(await pdfFile.exists(), isTrue);

    // Verify registered in DownloadManager
    expect(downloadManager.getCompletedDownloads().length, 10);
    // Discovered files must NOT appear in Recently Downloaded
    expect(downloadManager.getRecentlyDownloadedBooks(), isEmpty);
  });

  test('Traverses subdirectories inside Downloads folder', () async {
    final subDir = Directory('${downloadsDir.path}/Classics/Fantasy');
    await subDir.create(recursive: true);

    final file = File('${subDir.path}/The_Hobbit.epub');
    await file.writeAsString('Hobbit book data');

    final scanner = DownloadsScannerService(
      downloadManager: downloadManager,
      customDownloadsPath: downloadsDir.path,
    );

    final result = await scanner.scanDownloadsFolder();
    expect(result.isSuccess, isTrue);
    expect(result.count, 1);
    expect(result.discoveredTasks.first.bookTitle, 'The Hobbit');
  });

  test('Detects newly added files when rescanned', () async {
    final scanner = DownloadsScannerService(
      downloadManager: downloadManager,
      customDownloadsPath: downloadsDir.path,
    );

    // Initial scan: empty
    var result = await scanner.scanDownloadsFolder();
    expect(result.count, 0);

    // Add new file
    final newFile = File('${downloadsDir.path}/New_Arrival.epub');
    await newFile.writeAsString('New book content');

    // Rescan: detects new file
    result = await scanner.scanDownloadsFolder();
    expect(result.count, 1);
    expect(result.discoveredTasks.first.bookTitle, 'New Arrival');
  });

  test('Handles non-existent directory gracefully', () async {
    final scanner = DownloadsScannerService(
      downloadManager: downloadManager,
      customDownloadsPath: '${tempDir.path}/NonExistentFolder123',
    );

    final result = await scanner.scanDownloadsFolder();
    expect(result.isSuccess, isFalse);
    expect(result.status, DownloadsScanStatus.directoryNotFound);
    expect(result.errorMessage, contains('does not exist'));
  });
}

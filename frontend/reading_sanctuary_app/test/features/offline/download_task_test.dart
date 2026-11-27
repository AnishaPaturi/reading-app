import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/offline/domain/models/download_task.dart';

void main() {
  group('DownloadTask Unit Tests', () {
    test('Calculates progress accurately with clamp', () {
      const taskZero = DownloadTask(
        fileId: 'f1',
        bookId: 'b1',
        bookTitle: 'Book 1',
        fileName: 'book1.epub',
        format: 'EPUB',
        localPath: '/path/book1.epub',
        totalBytes: 0,
        downloadedBytes: 0,
      );
      expect(taskZero.progress, 0.0);

      const taskHalf = DownloadTask(
        fileId: 'f2',
        bookId: 'b2',
        bookTitle: 'Book 2',
        fileName: 'book2.pdf',
        format: 'PDF',
        localPath: '/path/book2.pdf',
        totalBytes: 1000,
        downloadedBytes: 500,
      );
      expect(taskHalf.progress, 0.5);

      const taskOver = DownloadTask(
        fileId: 'f3',
        bookId: 'b3',
        bookTitle: 'Book 3',
        fileName: 'book3.pdf',
        format: 'PDF',
        localPath: '/path/book3.pdf',
        totalBytes: 1000,
        downloadedBytes: 1500,
      );
      expect(taskOver.progress, 1.0);

      const taskCompleted = DownloadTask(
        fileId: 'f4',
        bookId: 'b4',
        bookTitle: 'Book 4',
        fileName: 'book4.pdf',
        format: 'PDF',
        localPath: '/path/book4.pdf',
        status: DownloadStatus.downloaded,
        totalBytes: 1000,
        downloadedBytes: 1000,
      );
      expect(taskCompleted.progress, 1.0);
      expect(taskCompleted.isCompleted, isTrue);
    });

    test('Status transitions and helper getters', () {
      const queued = DownloadTask(
        fileId: 'f1',
        bookId: 'b1',
        bookTitle: 'Title',
        fileName: 'file.epub',
        format: 'EPUB',
        localPath: '/p',
        status: DownloadStatus.queued,
      );
      expect(queued.isActive, isTrue);
      expect(queued.isDownloading, isFalse);
      expect(queued.isCompleted, isFalse);

      final downloading = queued.copyWith(status: DownloadStatus.downloading);
      expect(downloading.isActive, isTrue);
      expect(downloading.isDownloading, isTrue);

      final paused = downloading.copyWith(status: DownloadStatus.paused);
      expect(paused.isActive, isTrue);
      expect(paused.isPaused, isTrue);

      final failed = paused.copyWith(status: DownloadStatus.failed, errorMessage: 'Timeout');
      expect(failed.isActive, isFalse);
      expect(failed.isFailed, isTrue);
      expect(failed.errorMessage, 'Timeout');

      final cancelled = paused.copyWith(status: DownloadStatus.cancelled);
      expect(cancelled.isActive, isFalse);
      expect(cancelled.isCancelled, isTrue);

      final downloaded = downloading.copyWith(status: DownloadStatus.downloaded);
      expect(downloaded.isActive, isFalse);
      expect(downloaded.isCompleted, isTrue);
    });

    test('Recently downloaded book filtering: App download vs Discovered book', () {
      final now = DateTime.now();

      // App download that completed -> isRecentlyDownloaded MUST be true
      final appCompleted = DownloadTask(
        fileId: 'f-app-1',
        bookId: 'b1',
        bookTitle: 'App Downloaded Book',
        fileName: 'app.epub',
        format: 'EPUB',
        localPath: '/p/app.epub',
        status: DownloadStatus.downloaded,
        source: DownloadSource.appDownload,
        isDiscovered: false,
        downloadedAt: now,
      );
      expect(appCompleted.isRecentlyDownloaded, isTrue);

      // Discovered book from Downloads folder -> isRecentlyDownloaded MUST be false
      final discoveredBook = DownloadTask(
        fileId: 'f-disc-1',
        bookId: 'b2',
        bookTitle: 'Folder Discovered Book',
        fileName: 'disc.pdf',
        format: 'PDF',
        localPath: '/downloads/disc.pdf',
        status: DownloadStatus.downloaded,
        source: DownloadSource.folderDiscovered,
        isDiscovered: true,
        downloadedAt: null, // Never fabricate download dates!
        fileLastModified: now.subtract(const Duration(days: 3)),
      );
      expect(discoveredBook.isRecentlyDownloaded, isFalse);

      // In-flight app download -> isRecentlyDownloaded MUST be false
      final inFlight = appCompleted.copyWith(status: DownloadStatus.downloading);
      expect(inFlight.isRecentlyDownloaded, isFalse);

      // App download with null timestamp -> isRecentlyDownloaded MUST be false
      const noDate = DownloadTask(
        fileId: 'f-app-no-date',
        bookId: 'b1',
        bookTitle: 'App Downloaded Book No Date',
        fileName: 'app.epub',
        format: 'EPUB',
        localPath: '/p/app.epub',
        status: DownloadStatus.downloaded,
        source: DownloadSource.appDownload,
        isDiscovered: false,
        downloadedAt: null,
      );
      expect(noDate.isRecentlyDownloaded, isFalse);
    });

    test('Download-date sorting: Newest first and Oldest first', () {
      final now = DateTime.now();

      final tNew = DownloadTask(
        fileId: 'f-new',
        bookId: 'b1',
        bookTitle: 'New Book',
        fileName: 'new.epub',
        format: 'EPUB',
        localPath: '/p1',
        status: DownloadStatus.downloaded,
        downloadedAt: now,
      );

      final tMid = DownloadTask(
        fileId: 'f-mid',
        bookId: 'b2',
        bookTitle: 'Mid Book',
        fileName: 'mid.epub',
        format: 'EPUB',
        localPath: '/p2',
        status: DownloadStatus.downloaded,
        isDiscovered: true,
        source: DownloadSource.folderDiscovered,
        fileLastModified: now.subtract(const Duration(days: 2)),
      );

      final tOld = DownloadTask(
        fileId: 'f-old',
        bookId: 'b3',
        bookTitle: 'Old Book',
        fileName: 'old.epub',
        format: 'EPUB',
        localPath: '/p3',
        status: DownloadStatus.downloaded,
        downloadedAt: now.subtract(const Duration(days: 10)),
      );

      const tNoDate = DownloadTask(
        fileId: 'f-nodate',
        bookId: 'b4',
        bookTitle: 'Undated Book',
        fileName: 'undated.epub',
        format: 'EPUB',
        localPath: '/p4',
        status: DownloadStatus.downloaded,
      );

      final list = [tOld, tNoDate, tNew, tMid];

      // Newest first sorting
      list.sort((a, b) => DownloadTask.compareByDate(a, b, newestFirst: true));
      expect(list.map((t) => t.fileId).toList(), ['f-new', 'f-mid', 'f-old', 'f-nodate']);

      // Oldest first sorting
      list.sort((a, b) => DownloadTask.compareByDate(a, b, newestFirst: false));
      expect(list.map((t) => t.fileId).toList(), ['f-old', 'f-mid', 'f-new', 'f-nodate']);
    });

    test('JSON serialization & backward compatibility', () {
      final now = DateTime.now();
      final task = DownloadTask(
        fileId: 'f-ser',
        bookId: 'b-ser',
        bookTitle: 'Serialization Book',
        author: 'Robert C. Martin',
        coverUrl: 'https://example.com/cover.jpg',
        fileName: 'clean.pdf',
        format: 'PDF',
        localPath: '/local/clean.pdf',
        totalBytes: 5000000,
        downloadedBytes: 5000000,
        status: DownloadStatus.downloaded,
        source: DownloadSource.appDownload,
        isDiscovered: false,
        checksum: 'sha256hash',
        downloadedAt: now,
      );

      final json = task.toJson();
      expect(json['fileId'], 'f-ser');
      expect(json['author'], 'Robert C. Martin');
      expect(json['isDiscovered'], isFalse);
      expect(json['source'], 'appDownload');

      final deserialized = DownloadTask.fromJson(json);
      expect(deserialized.fileId, 'f-ser');
      expect(deserialized.author, 'Robert C. Martin');
      expect(deserialized.bookTitle, 'Serialization Book');
      expect(deserialized.isDiscovered, isFalse);
      expect(deserialized.source, DownloadSource.appDownload);
      expect(deserialized.status, DownloadStatus.downloaded);

      // Backward compatibility with legacy json lacking new fields
      final legacyJson = {
        'fileId': 'legacy-1',
        'bookId': 'b-leg',
        'bookTitle': 'Legacy Book',
        'fileName': 'leg.epub',
        'format': 'EPUB',
        'localPath': '/leg.epub',
        'totalBytes': 1234,
        'downloadedBytes': 1234,
        'status': 'downloaded',
      };
      final fromLegacy = DownloadTask.fromJson(legacyJson);
      expect(fromLegacy.fileId, 'legacy-1');
      expect(fromLegacy.isDiscovered, isFalse);
      expect(fromLegacy.source, DownloadSource.appDownload);
      expect(fromLegacy.author, isNull);
    });
  });
}

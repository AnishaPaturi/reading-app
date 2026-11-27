import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/datasources/audiobook_local_datasource.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/datasources/audiobook_storage.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_settings.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_track.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audiobook.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audiobook_bookmark.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/listening_event.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/playback_progress.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_widget_service.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/scan_folder.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/desktop_book_scanner.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/platform/web_book_scanner.dart';

class _SimulatedBrowserStorageBackend implements AudiobookStorageBackend {
  final Map<String, String> backingMap;
  bool failInit;
  bool failWrite = false;

  _SimulatedBrowserStorageBackend({
    Map<String, String>? backingMap,
    this.failInit = false,
  }) : backingMap = backingMap ?? <String, String>{};

  @override
  Future<void> init() async {
    if (failInit) {
      throw const AudiobookStorageException('IndexedDB unavailable');
    }
  }

  @override
  Future<String?> readStore(String key) async => backingMap[key];

  @override
  Future<void> writeStore(String key, String value) async {
    if (failWrite) {
      throw const AudiobookStorageException('QuotaExceededError');
    }
    backingMap[key] = value;
  }
}

void main() {
  group('AudiobookLocalDatasource Persistent Storage & Error Handling', () {
    test('persists and reloads all collections across datasource instances', () async {
      final sharedBrowserDb = <String, String>{};

      final ds1 = AudiobookLocalDatasource(
        storageBackend: _SimulatedBrowserStorageBackend(backingMap: sharedBrowserDb),
      );
      await ds1.init();

      final book = Audiobook(
        id: 'book-1',
        title: 'Project Hail Mary',
        author: 'Andy Weir',
        totalDurationMs: 1800000,
        totalTracks: 1,
        status: AudiobookStatus.current,
        dateAdded: DateTime(2026, 3, 1),
      );
      const track = AudioTrack(
        id: 'track-1',
        audiobookId: 'book-1',
        filePath: 'https://example.com/hail_mary.mp3',
        fileName: 'hail_mary.mp3',
        trackOrder: 1,
        durationMs: 1800000,
        format: 'MP3',
      );
      await ds1.saveAudiobook(book, [track]);

      await ds1.saveProgressRecord(
        PlaybackProgress(
          audiobookId: 'book-1',
          currentTrackId: 'track-1',
          trackIndex: 0,
          positionMs: 42000,
          totalDurationMs: 1800000,
          playbackSpeed: 1.5,
          lastListenedAt: DateTime(2026, 3, 2),
          completed: false,
        ),
      );

      await ds1.saveBookmark(
        AudiobookBookmark(
          id: 'bm-1',
          audiobookId: 'book-1',
          trackIndex: 0,
          positionMs: 12000,
          title: 'Chapter Start',
          createdAt: DateTime(2026, 3, 2),
        ),
      );

      await ds1.recordSession(
        ListeningSession(
          id: 's-1',
          audiobookId: 'book-1',
          startedAt: DateTime(2026, 3, 2, 10),
          actualListeningMs: 30000,
        ),
      );
      await ds1.recordSession(
        ListeningSession(
          id: 's-2',
          audiobookId: 'book-1',
          startedAt: DateTime(2026, 3, 2, 12),
          actualListeningMs: 45000,
        ),
      );

      await ds1.saveSettings(const AudioSettings(playbackSpeed: 1.5, nightAppearance: true));

      // Re-instantiate datasource (simulating full browser page reload)
      final ds2 = AudiobookLocalDatasource(
        storageBackend: _SimulatedBrowserStorageBackend(backingMap: sharedBrowserDb),
      );
      await ds2.init();

      expect(ds2.getAllAudiobooks().length, 1);
      expect(ds2.getAudiobook('book-1')?.title, 'Project Hail Mary');
      expect(ds2.getTracksForBook('book-1').length, 1);
      expect(ds2.getProgress('book-1')?.positionMs, 42000);
      expect(ds2.getBookmarks('book-1').length, 1);
      expect(ds2.getSettings().playbackSpeed, 1.5);
      expect(ds2.getSettings().nightAppearance, isTrue);

      // Verify getAllSessions sorts without throwing on unmodifiable list
      final sessions = ds2.getAllSessions();
      expect(sessions.map((s) => s.id).toList(), ['s-2', 's-1']);
      expect(() => sessions.sort((a, b) => a.id.compareTo(b.id)), throwsUnsupportedError);
    });

    test('handles null/missing records gracefully when stores are empty', () async {
      final ds = AudiobookLocalDatasource(
        storageBackend: _SimulatedBrowserStorageBackend(),
      );
      await ds.init();

      expect(ds.getAllAudiobooks(), isEmpty);
      expect(ds.getAudiobook('missing-id'), isNull);
      expect(ds.getTracksForBook('missing-id'), isEmpty);
      expect(ds.getChaptersForBook('missing-id'), isEmpty);
      expect(ds.getProgress('missing-id'), isNull);
      expect(ds.getBookmarks('missing-id'), isEmpty);
      expect(ds.getAllBookmarks(), isEmpty);
      expect(ds.getSessionsForBook('missing-id'), isEmpty);
      expect(ds.getAllSessions(), isEmpty);
    });

    test('does not silently fall back to memory when storage init fails', () async {
      final ds = AudiobookLocalDatasource(
        storageBackend: _SimulatedBrowserStorageBackend(failInit: true),
      );

      await expectLater(ds.init(), throwsA(isA<AudiobookStorageException>()));
      expect(ds.isInitialized, isFalse);
    });

    test('rolls back in-memory state and rethrows when storage write fails', () async {
      final backend = _SimulatedBrowserStorageBackend();
      final ds = AudiobookLocalDatasource(storageBackend: backend);
      await ds.init();

      backend.failWrite = true;

      final book = Audiobook(
        id: 'book-fail',
        title: 'Fail Book',
        author: 'Author',
        totalDurationMs: 1000,
        totalTracks: 0,
        status: AudiobookStatus.notStarted,
        dateAdded: DateTime(2026, 3, 1),
      );

      await expectLater(
        ds.saveAudiobook(book, const []),
        throwsA(isA<AudiobookStorageException>()),
      );
      expect(ds.getAudiobook('book-fail'), isNull);

      await expectLater(
        ds.saveSettings(const AudioSettings(playbackSpeed: 2.0)),
        throwsA(isA<AudiobookStorageException>()),
      );
      expect(ds.getSettings().playbackSpeed, 1.0);
    });

    test('throws explicit AudiobookStorageException on corrupted store JSON', () async {
      final ds = AudiobookLocalDatasource(
        storageBackend: _SimulatedBrowserStorageBackend(
          backingMap: {'sanctuary_audiobooks': '{not-valid-json'},
        ),
      );

      await expectLater(ds.init(), throwsA(isA<AudiobookStorageException>()));
      expect(ds.isInitialized, isFalse);
    });
  });

  group('Platform-specific plugin handling', () {
    test('AudiobookWidgetService no-ops safely off Android without throwing', () async {
      await AudiobookWidgetService.initialize();
      await AudiobookWidgetService.updateNowPlaying(
        title: 'Test',
        author: 'Author',
        isPlaying: false,
        positionMs: 0,
        durationMs: 1000,
        audiobookId: 'id-1',
      );
      await AudiobookWidgetService.updateShelfWidget(recentBooks: const []);
    });

    test('WebBookScanner and DesktopBookScanner implement PlatformBookScanner cleanly', () async {
      const dummyFolder = ScanFolder(
        id: 'folder-1',
        name: 'Books',
        pathOrUri: 'web_session://1',
        isDefault: false,
        folderType: FolderType.custom,
        status: FolderAccessStatus.active,
      );

      final webScanner = WebBookScanner();
      expect(webScanner.platformCapabilitiesDescription, isNotEmpty);
      expect(await webScanner.verifyPermission(dummyFolder), isFalse);
      expect(await webScanner.scanFolder(dummyFolder), isEmpty);

      final desktopScanner = DesktopBookScanner();
      expect(desktopScanner.platformCapabilitiesDescription, isNotEmpty);
    });

    test('IoAudiobookStorageBackend preserves native file persistence across instances', () async {
      final tempDir = await Directory.systemTemp.createTemp('rs_audiobook_io_test_');
      try {
        final ds1 = AudiobookLocalDatasource(customDirectoryPath: tempDir.path);
        await ds1.init();

        final book = Audiobook(
          id: 'io-book-1',
          title: 'Native Persistence',
          author: 'Android Author',
          totalDurationMs: 90000,
          totalTracks: 1,
          status: AudiobookStatus.notStarted,
          dateAdded: DateTime(2026, 4, 1),
        );
        const track = AudioTrack(
          id: 'io-track-1',
          audiobookId: 'io-book-1',
          filePath: '/storage/emulated/0/Audiobooks/track.mp3',
          fileName: 'track.mp3',
          trackOrder: 1,
          durationMs: 90000,
          format: 'MP3',
        );
        await ds1.saveAudiobook(book, [track]);

        final ds2 = AudiobookLocalDatasource(customDirectoryPath: tempDir.path);
        await ds2.init();
        expect(ds2.getAllAudiobooks().length, 1);
        expect(ds2.getAudiobook('io-book-1')?.title, 'Native Persistence');
        expect(ds2.getTracksForBook('io-book-1').single.fileName, 'track.mp3');
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}

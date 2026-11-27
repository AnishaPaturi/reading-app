@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/datasources/audiobook_local_datasource.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_settings.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_track.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audiobook.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audiobook_bookmark.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/listening_event.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/playback_progress.dart';

void main() {
  group('Flutter Web IndexedDB AudiobookLocalDatasource', () {
    test('persists audiobooks, tracks, progress, bookmarks, sessions, and settings in IndexedDB', () async {
      final ds1 = AudiobookLocalDatasource();
      await ds1.init();
      expect(ds1.isInitialized, isTrue);

      final book = Audiobook(
        id: 'web-idb-book-1',
        title: 'Web IndexedDB Book',
        author: 'Browser Author',
        totalDurationMs: 120000,
        totalTracks: 1,
        status: AudiobookStatus.current,
        dateAdded: DateTime(2026, 6, 1),
      );
      const track = AudioTrack(
        id: 'web-idb-track-1',
        audiobookId: 'web-idb-book-1',
        filePath: 'https://example.com/audio.mp3',
        fileName: 'audio.mp3',
        trackOrder: 1,
        durationMs: 120000,
        format: 'MP3',
      );
      await ds1.saveAudiobook(book, [track]);
      await ds1.saveProgressRecord(
        PlaybackProgress(
          audiobookId: 'web-idb-book-1',
          currentTrackId: 'web-idb-track-1',
          trackIndex: 0,
          positionMs: 15000,
          totalDurationMs: 120000,
          playbackSpeed: 1.25,
          lastListenedAt: DateTime(2026, 6, 2),
          completed: false,
        ),
      );
      await ds1.saveBookmark(
        AudiobookBookmark(
          id: 'web-bm-1',
          audiobookId: 'web-idb-book-1',
          trackIndex: 0,
          positionMs: 15000,
          title: 'Key Quote',
          createdAt: DateTime(2026, 6, 2),
        ),
      );
      await ds1.recordSession(
        ListeningSession(
          id: 'web-sess-1',
          audiobookId: 'web-idb-book-1',
          startedAt: DateTime(2026, 6, 2),
          actualListeningMs: 15000,
        ),
      );
      await ds1.saveSettings(const AudioSettings(playbackSpeed: 1.25));

      // Fresh instance simulating a browser reload
      final ds2 = AudiobookLocalDatasource();
      await ds2.init();

      expect(ds2.getAudiobook('web-idb-book-1')?.title, 'Web IndexedDB Book');
      expect(ds2.getTracksForBook('web-idb-book-1').length, 1);
      expect(ds2.getProgress('web-idb-book-1')?.positionMs, 15000);
      expect(ds2.getBookmarks('web-idb-book-1').length, 1);
      expect(ds2.getAllSessions().any((s) => s.id == 'web-sess-1'), isTrue);
      expect(ds2.getSettings().playbackSpeed, 1.25);

      // Clean up test record from browser IndexedDB
      await ds2.deleteAudiobook('web-idb-book-1');
    });
  });
}

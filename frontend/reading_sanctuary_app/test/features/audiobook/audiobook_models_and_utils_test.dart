import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audiobook.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_track.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/playback_progress.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audiobook_bookmark.dart';
import 'package:reading_sanctuary_app/features/audiobook/utils/audio_format_utils.dart';
import 'package:reading_sanctuary_app/features/audiobook/utils/audiobook_duration_utils.dart';
import 'package:reading_sanctuary_app/features/audiobook/utils/audiobook_grouping_utils.dart';

void main() {
  group('AudioFormatUtils', () {
    test('recognizes supported audio formats', () {
      expect(AudioFormatUtils.isSupported('book.mp3'), isTrue);
      expect(AudioFormatUtils.isSupported('audio.m4b'), isTrue);
      expect(AudioFormatUtils.isSupported('track.m4a'), isTrue);
      expect(AudioFormatUtils.isSupported('sound.ogg'), isTrue);
      expect(AudioFormatUtils.isSupported('voice.opus'), isTrue);
      expect(AudioFormatUtils.isSupported('document.pdf'), isFalse);
      expect(AudioFormatUtils.isSupported('book.epub'), isFalse);
    });
  });

  group('AudiobookGroupingUtils', () {
    test('naturalCompare correctly sorts numbered chapter filenames', () {
      final list = [
        'Chapter 10.mp3',
        'Chapter 1.mp3',
        'Chapter 2.mp3',
        'Chapter 20.mp3',
      ];
      list.sort(AudiobookGroupingUtils.naturalCompare);
      expect(list, [
        'Chapter 1.mp3',
        'Chapter 2.mp3',
        'Chapter 10.mp3',
        'Chapter 20.mp3',
      ]);
    });

    test('cleanTrackTitle strips leading track prefixes', () {
      expect(AudiobookGroupingUtils.cleanTrackTitle('01 - Introduction.mp3'), 'Introduction');
      expect(AudiobookGroupingUtils.cleanTrackTitle('02. Chapter One.mp3'), 'Chapter One');
      expect(AudiobookGroupingUtils.cleanTrackTitle('Chapter 03 - The Silent Patient.mp3'), 'The Silent Patient');
    });
  });

  group('AudiobookDurationUtils', () {
    test('formatDuration formats correctly', () {
      expect(AudiobookDurationUtils.formatDuration(const Duration(seconds: 45)), '00:45');
      expect(AudiobookDurationUtils.formatDuration(const Duration(minutes: 5, seconds: 30)), '05:30');
      expect(AudiobookDurationUtils.formatDuration(const Duration(hours: 2, minutes: 15, seconds: 4)), '02:15:04');
    });

    test('calculateStatus transitions between notStarted, current, completed', () {
      expect(
        AudiobookDurationUtils.calculateStatus(
          positionMs: 0,
          totalDurationMs: 600000,
          explicitlyCompleted: false,
        ),
        AudiobookStatus.notStarted,
      );

      expect(
        AudiobookDurationUtils.calculateStatus(
          positionMs: 120000,
          totalDurationMs: 600000,
          explicitlyCompleted: false,
        ),
        AudiobookStatus.current,
      );

      expect(
        AudiobookDurationUtils.calculateStatus(
          positionMs: 595000,
          totalDurationMs: 600000,
          explicitlyCompleted: false,
        ),
        AudiobookStatus.completed,
      );

      expect(
        AudiobookDurationUtils.calculateStatus(
          positionMs: 10000,
          totalDurationMs: 600000,
          explicitlyCompleted: true,
        ),
        AudiobookStatus.completed,
      );
    });
  });

  group('Audiobook and Models serialization', () {
    test('Audiobook json roundtrip', () {
      final now = DateTime.now();
      final book = Audiobook(
        id: 'book-1',
        title: 'The Silent Patient',
        author: 'Alex Michaelides',
        narrator: 'Jack Hawkins',
        description: 'A psychological thriller.',
        coverPath: '/covers/book1.jpg',
        folderPath: '/audiobooks/silent_patient',
        totalDurationMs: 3600000,
        totalTracks: 12,
        status: AudiobookStatus.current,
        dateAdded: now,
      );

      final json = book.toJson();
      final revived = Audiobook.fromJson(json);

      expect(revived.id, book.id);
      expect(revived.title, book.title);
      expect(revived.author, book.author);
      expect(revived.narrator, book.narrator);
      expect(revived.totalDurationMs, book.totalDurationMs);
      expect(revived.status, AudiobookStatus.current);
    });

    test('PlaybackProgress json roundtrip', () {
      final progress = PlaybackProgress(
        audiobookId: 'book-1',
        currentTrackId: 'track-3',
        trackIndex: 2,
        positionMs: 45000,
        totalDurationMs: 3600000,
        playbackSpeed: 1.25,
        lastListenedAt: DateTime.now(),
        completed: false,
      );

      final json = progress.toJson();
      final revived = PlaybackProgress.fromJson(json);

      expect(revived.audiobookId, 'book-1');
      expect(revived.trackIndex, 2);
      expect(revived.positionMs, 45000);
      expect(revived.playbackSpeed, 1.25);
    });

    test('AudiobookBookmark json roundtrip', () {
      final bookmark = AudiobookBookmark(
        id: 'bm-1',
        audiobookId: 'book-1',
        trackId: 'track-2',
        trackIndex: 1,
        positionMs: 15400,
        title: 'Great observation',
        note: 'Remember this character quote',
        category: 'quote',
        isFavorite: true,
        createdAt: DateTime.now(),
      );

      final json = bookmark.toJson();
      final revived = AudiobookBookmark.fromJson(json);

      expect(revived.id, 'bm-1');
      expect(revived.category, 'quote');
      expect(revived.isFavorite, isTrue);
      expect(revived.note, 'Remember this character quote');
    });
  });
}

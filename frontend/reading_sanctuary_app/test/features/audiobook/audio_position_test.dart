import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_position.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_track.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/repositories/audiobook_repository.dart';
import 'package:reading_sanctuary_app/features/audiobook/domain/services/audio_position_service.dart';

class FakeAudiobookRepository implements AudiobookRepository {
  AudioPosition? savedPosition;
  bool isCompletedSaved = false;

  @override
  Future<AudioPosition?> getPosition({
    required String bookId,
    required String fileId,
  }) async {
    return savedPosition;
  }

  @override
  Future<AudioPosition> savePosition({
    required String bookId,
    required String fileId,
    required AudioPosition position,
    required bool isCompleted,
  }) async {
    savedPosition = position;
    isCompletedSaved = isCompleted;
    return position;
  }

  @override
  Future<void> resetPosition({
    required String bookId,
    required String fileId,
  }) async {
    savedPosition = null;
    isCompletedSaved = false;
  }
}

void main() {
  group('AudioPosition & AudioTrack Model Tests', () {
    test('AudioPosition fromJson and toJson roundtrip', () {
      final json = {
        'positionMs': 120000,
        'durationMs': 600000,
        'playbackSpeed': 1.25,
        'isCompleted': false,
        'updatedAt': '2026-11-09T07:00:00.000Z',
      };

      final pos = AudioPosition.fromJson(json);
      expect(pos.positionMs, 120000);
      expect(pos.durationMs, 600000);
      expect(pos.playbackSpeed, 1.25);
      expect(pos.isCompleted, false);

      final outJson = pos.toJson();
      expect(outJson['positionMs'], 120000);
      expect(outJson['durationMs'], 600000);
      expect(outJson['playbackSpeed'], 1.25);
    });

    test('AudioTrack fromJson parses correctly', () {
      final json = {
        'id': 'file-123',
        'bookId': 'book-456',
        'fileName': 'Chapter 1.mp3',
        'fileFormat': 'MP3',
        'fileSizeBytes': 1048576,
      };

      final track = AudioTrack.fromJson(json);
      expect(track.fileId, 'file-123');
      expect(track.bookId, 'book-456');
      expect(track.title, 'Chapter 1.mp3');
      expect(track.format, 'MP3');
      expect(track.fileSizeBytes, 1048576);
    });
  });

  group('AudioPositionService Tests', () {
    late FakeAudiobookRepository fakeRepo;
    late AudioPositionService service;

    setUp(() {
      fakeRepo = FakeAudiobookRepository();
      service = AudioPositionService(repository: fakeRepo);
    });

    tearDown(() {
      service.dispose();
    });

    test('saveImmediately persists position to repository', () async {
      final pos = AudioPosition(
        positionMs: 45000,
        durationMs: 90000,
        playbackSpeed: 1.5,
        updatedAt: DateTime.now(),
      );

      final result = await service.saveImmediately(
        bookId: 'b1',
        fileId: 'f1',
        position: pos,
      );

      expect(result, isNotNull);
      expect(fakeRepo.savedPosition?.positionMs, 45000);
      expect(fakeRepo.savedPosition?.playbackSpeed, 1.5);
    });

    test('resetPosition clears repository position', () async {
      final pos = AudioPosition(
        positionMs: 1000,
        durationMs: 5000,
        playbackSpeed: 1.0,
        updatedAt: DateTime.now(),
      );
      await service.saveImmediately(bookId: 'b1', fileId: 'f1', position: pos);
      expect(fakeRepo.savedPosition, isNotNull);

      await service.resetPosition(bookId: 'b1', fileId: 'f1');
      expect(fakeRepo.savedPosition, isNull);
    });
  });
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/audio_position.dart';
import '../../data/repositories/audiobook_repository.dart';

class AudioPositionService {
  final AudiobookRepository repository;
  Timer? _debounceTimer;
  AudioPosition? _lastSavedPosition;

  AudioPositionService({required this.repository});

  Future<AudioPosition?> getPosition({
    required String bookId,
    required String fileId,
  }) async {
    return await repository.getPosition(bookId: bookId, fileId: fileId);
  }

  void scheduleSave({
    required String bookId,
    required String fileId,
    required AudioPosition position,
    bool isCompleted = false,
    Duration delay = const Duration(seconds: 5),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () async {
      await saveImmediately(
        bookId: bookId,
        fileId: fileId,
        position: position,
        isCompleted: isCompleted,
      );
    });
  }

  Future<AudioPosition?> saveImmediately({
    required String bookId,
    required String fileId,
    required AudioPosition position,
    bool isCompleted = false,
  }) async {
    _debounceTimer?.cancel();
    try {
      _lastSavedPosition = await repository.savePosition(
        bookId: bookId,
        fileId: fileId,
        position: position,
        isCompleted: isCompleted,
      );
      return _lastSavedPosition;
    } catch (e) {
      debugPrint('Error saving audio position: $e');
      return null;
    }
  }

  Future<void> resetPosition({
    required String bookId,
    required String fileId,
  }) async {
    _debounceTimer?.cancel();
    await repository.resetPosition(bookId: bookId, fileId: fileId);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

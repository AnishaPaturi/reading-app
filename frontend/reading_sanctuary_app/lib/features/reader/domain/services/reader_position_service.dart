import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/reader_position.dart';
import '../../data/repositories/reader_repository.dart';

class ReaderPositionService {
  final ReaderRepository repository;
  final Duration debounceDuration;

  Timer? _debounceTimer;
  ReaderPosition? _pendingPosition;
  String? _currentBookId;
  String? _currentFileId;

  ReaderPositionService({
    required this.repository,
    this.debounceDuration = const Duration(seconds: 2),
  });

  void onPositionChanged({
    required String bookId,
    required String fileId,
    required ReaderPosition position,
    VoidCallback? onSaved,
  }) {
    _currentBookId = bookId;
    _currentFileId = fileId;
    _pendingPosition = position;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () async {
      await flushPending();
      onSaved?.call();
    });
  }

  Future<void> flushPending() async {
    _debounceTimer?.cancel();
    if (_pendingPosition != null && _currentBookId != null && _currentFileId != null) {
      try {
        await repository.savePosition(
          bookId: _currentBookId!,
          fileId: _currentFileId!,
          position: _pendingPosition!,
        );
      } catch (e) {
        debugPrint('Failed to save debounced position: $e');
      } finally {
        _pendingPosition = null;
      }
    }
  }

  void dispose() {
    flushPending();
  }
}

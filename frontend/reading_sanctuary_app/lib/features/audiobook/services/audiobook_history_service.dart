import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/datasources/audiobook_local_datasource.dart';
import '../data/models/audiobook.dart';
import '../data/models/listening_event.dart';

class ResumeSuggestion {
  final Audiobook audiobook;
  final int trackIndex;
  final int positionMs;
  final String? chapterTitle;
  final DateTime lastListenedAt;

  const ResumeSuggestion({
    required this.audiobook,
    required this.trackIndex,
    required this.positionMs,
    this.chapterTitle,
    required this.lastListenedAt,
  });
}

class AudiobookHistoryService {
  final AudiobookLocalDatasource _localDatasource;
  final Uuid _uuid = const Uuid();

  ListeningSession? _currentSession;
  DateTime? _lastPlayTimestamp;

  AudiobookHistoryService({AudiobookLocalDatasource? localDatasource})
      : _localDatasource = localDatasource ?? AudiobookLocalDatasource();

  void onPlaybackStarted(String audiobookId, int trackIndex, int positionMs) {
    final now = DateTime.now();
    _lastPlayTimestamp = now;

    if (_currentSession == null || _currentSession!.audiobookId != audiobookId) {
      _currentSession = ListeningSession(
        id: _uuid.v4(),
        audiobookId: audiobookId,
        startedAt: now,
        actualListeningMs: 0,
      );
    }

    _logEvent('play', trackIndex, positionMs);
  }

  void _persistSession(ListeningSession session) {
    unawaited(
      _localDatasource.recordSession(session).catchError((Object e) {
        debugPrint('AudiobookHistoryService: failed to persist session: $e');
      }),
    );
  }

  void _persistEvent(ListeningEvent event) {
    unawaited(
      _localDatasource.recordEvent(event).catchError((Object e) {
        debugPrint('AudiobookHistoryService: failed to persist event: $e');
      }),
    );
  }

  void onPlaybackPaused(int trackIndex, int positionMs) {
    if (_lastPlayTimestamp != null && _currentSession != null) {
      final elapsed = DateTime.now().difference(_lastPlayTimestamp!).inMilliseconds;
      _currentSession = _currentSession!.copyWith(
        actualListeningMs: _currentSession!.actualListeningMs + elapsed,
      );
      _lastPlayTimestamp = null;
      _persistSession(_currentSession!);
    }

    _logEvent('pause', trackIndex, positionMs);
  }

  void onSeek(int trackIndex, int positionMs, bool forward) {
    _logEvent(forward ? 'seekForward' : 'seekBackward', trackIndex, positionMs);
  }

  void onTrackChanged(int trackIndex, int positionMs) {
    _logEvent('trackChanged', trackIndex, positionMs);
  }

  void onPlaybackCompleted(int trackIndex, int positionMs) {
    endSession();
    _logEvent('completed', trackIndex, positionMs);
  }

  void endSession() {
    if (_lastPlayTimestamp != null && _currentSession != null) {
      final elapsed = DateTime.now().difference(_lastPlayTimestamp!).inMilliseconds;
      _currentSession = _currentSession!.copyWith(
        actualListeningMs: _currentSession!.actualListeningMs + elapsed,
        endedAt: DateTime.now(),
      );
      _lastPlayTimestamp = null;
      _persistSession(_currentSession!);
    } else if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(endedAt: DateTime.now());
      _persistSession(_currentSession!);
    }
    _currentSession = null;
  }

  void _logEvent(String eventType, int trackIndex, int positionMs) {
    if (_currentSession == null) return;
    final event = ListeningEvent(
      id: _uuid.v4(),
      sessionId: _currentSession!.id,
      eventType: eventType,
      trackIndex: trackIndex,
      positionMs: positionMs,
      createdAt: DateTime.now(),
    );
    _persistEvent(event);
  }

  List<ListeningSession> getHistoryForBook(String bookId) {
    return _localDatasource.getSessionsForBook(bookId);
  }

  List<ListeningSession> getAllHistory() {
    return _localDatasource.getAllSessions();
  }

  /// Finds unfinished audiobooks and generates a resume suggestion
  ResumeSuggestion? getLatestResumeSuggestion() {
    final allBooks = _localDatasource.getAllAudiobooks();
    Audiobook? mostRecentBook;
    DateTime? mostRecentTime;
    int resumeTrackIndex = 0;
    int resumePositionMs = 0;

    for (final book in allBooks) {
      final progress = _localDatasource.getProgress(book.id);
      if (progress != null && !progress.completed && progress.positionMs > 0) {
        if (mostRecentTime == null || progress.lastListenedAt.isAfter(mostRecentTime)) {
          mostRecentTime = progress.lastListenedAt;
          mostRecentBook = book;
          resumeTrackIndex = progress.trackIndex;
          resumePositionMs = progress.positionMs;
        }
      }
    }

    if (mostRecentBook != null && mostRecentTime != null) {
      final tracks = _localDatasource.getTracksForBook(mostRecentBook.id);
      final currentTrack = resumeTrackIndex < tracks.length ? tracks[resumeTrackIndex] : null;

      return ResumeSuggestion(
        audiobook: mostRecentBook,
        trackIndex: resumeTrackIndex,
        positionMs: resumePositionMs,
        chapterTitle: currentTrack?.chapterTitle ?? currentTrack?.fileName,
        lastListenedAt: mostRecentTime,
      );
    }

    return null;
  }
}

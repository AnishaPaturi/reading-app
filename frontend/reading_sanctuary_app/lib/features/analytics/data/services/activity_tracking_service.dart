import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/activity_session.dart';
import '../repositories/analytics_repository.dart';

class ActivityTrackingService {
  final AnalyticsRepository _repository;
  Timer? _heartbeatTimer;

  String? _currentSessionId;
  ActivityType? _currentActivityType;
  String? _currentBookId;
  String? _currentFileId;
  String? _currentLocation;
  int? _currentPage;
  int _pendingPagesRead = 0;
  double? _currentPlaybackSpeed;
  bool _isClosing = false;

  ActivityTrackingService(this._repository);

  String? get currentSessionId => _currentSessionId;
  ActivityType? get currentActivityType => _currentActivityType;
  bool get hasActiveSession => _currentSessionId != null;

  /// Starts a tracking session for reading, audiobook, or TTS.
  /// If a session is already active for a different activity or book, the previous session is closed first.
  Future<void> startSession({
    required ActivityType activityType,
    String? bookId,
    String? bookFileId,
    String? startingLocation,
    int? startingPage,
    double? playbackSpeed,
  }) async {
    // If identical session is already active, don't restart
    if (_currentSessionId != null &&
        _currentActivityType == activityType &&
        _currentBookId == bookId &&
        _currentFileId == bookFileId) {
      return;
    }

    // Close any existing session first
    if (_currentSessionId != null) {
      await closeSession();
    }

    _currentActivityType = activityType;
    _currentBookId = bookId;
    _currentFileId = bookFileId;
    _currentLocation = startingLocation;
    _currentPage = startingPage;
    _pendingPagesRead = 0;
    _currentPlaybackSpeed = playbackSpeed;

    try {
      final session = await _repository.startSession(
        ActivitySessionRequest(
          activityType: activityType,
          bookId: bookId,
          bookFileId: bookFileId,
          startingLocation: startingLocation,
          startingPage: startingPage,
          playbackSpeed: playbackSpeed,
        ),
      );
      _currentSessionId = session.id;
      _startHeartbeatTimer();
    } catch (e) {
      debugPrint('ActivityTrackingService: Failed to start session: $e');
    }
  }

  /// Updates current reading location, page, and progress.
  void updateProgress({
    String? currentLocation,
    int? currentPage,
    int pagesReadDelta = 0,
    double? playbackSpeed,
  }) {
    if (currentLocation != null) _currentLocation = currentLocation;
    if (currentPage != null) {
      if (_currentPage != null && currentPage > _currentPage!) {
        _pendingPagesRead += (currentPage - _currentPage!);
      }
      _currentPage = currentPage;
    }
    if (pagesReadDelta > 0) {
      _pendingPagesRead += pagesReadDelta;
    }
    if (playbackSpeed != null) {
      _currentPlaybackSpeed = playbackSpeed;
    }
  }

  void _startHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _sendHeartbeat();
    });
  }

  Future<void> _sendHeartbeat() async {
    final sessionId = _currentSessionId;
    if (sessionId == null || _isClosing) return;

    final pagesDelta = _pendingPagesRead;
    _pendingPagesRead = 0; // reset delta

    try {
      await _repository.sendHeartbeat(
        sessionId,
        ActivityHeartbeatRequest(
          intervalSeconds: 30,
          currentLocation: _currentLocation,
          currentPage: _currentPage,
          pagesReadDelta: pagesDelta > 0 ? pagesDelta : null,
          playbackSpeed: _currentPlaybackSpeed,
        ),
      );
    } catch (e) {
      debugPrint('ActivityTrackingService: Heartbeat error: $e');
      // restore pending pages delta if failed so it can retry next beat
      _pendingPagesRead += pagesDelta;
    }
  }

  /// Closes the active session and cancels the heartbeat timer.
  Future<void> closeSession() async {
    final sessionId = _currentSessionId;
    if (sessionId == null || _isClosing) return;

    _isClosing = true;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    final pagesDelta = _pendingPagesRead;
    _pendingPagesRead = 0;

    try {
      await _repository.closeSession(
        sessionId,
        CloseSessionRequest(
          endingLocation: _currentLocation,
          endingPage: _currentPage,
          pagesReadDelta: pagesDelta > 0 ? pagesDelta : null,
        ),
      );
    } catch (e) {
      debugPrint('ActivityTrackingService: Failed to close session: $e');
    } finally {
      _currentSessionId = null;
      _currentActivityType = null;
      _currentBookId = null;
      _currentFileId = null;
      _currentLocation = null;
      _currentPage = null;
      _currentPlaybackSpeed = null;
      _isClosing = false;
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}

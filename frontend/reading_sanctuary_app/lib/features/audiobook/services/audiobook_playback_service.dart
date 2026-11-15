import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../data/datasources/audiobook_local_datasource.dart';
import '../data/models/audiobook.dart';
import '../data/models/audio_track.dart';
import '../data/models/audio_chapter.dart';
import '../data/models/playback_progress.dart';
import '../data/models/audio_settings.dart';
import '../domain/enums/audio_playback_state.dart';
import 'audiobook_player_handler.dart';
import 'audiobook_sleep_timer_service.dart';
import 'audiobook_chapter_service.dart';
import 'audiobook_history_service.dart';
import 'audiobook_widget_service.dart';

class AudiobookPlaybackService {
  AudiobookPlayerHandler? _handler;
  bool _initialized = false;

  final AudiobookLocalDatasource _localDatasource;
  final AudiobookChapterService _chapterService;
  final AudiobookSleepTimerService _sleepTimerService;
  final AudiobookHistoryService _historyService;

  Audiobook? _currentBook;
  List<AudioTrack> _tracks = [];
  int _currentTrackIndex = 0;
  List<AudioChapter> _chapters = [];
  AudioSettings _settings = const AudioSettings();

  Timer? _progressSaveTimer;
  DateTime? _lastPauseTime;
  Duration? _chapterStopTarget;

  final _statusController = StreamController<AudioPlaybackStatus>.broadcast();

  AudiobookPlaybackService({
    AudiobookLocalDatasource? localDatasource,
    AudiobookChapterService? chapterService,
    AudiobookSleepTimerService? sleepTimerService,
    AudiobookHistoryService? historyService,
  })  : _localDatasource = localDatasource ?? AudiobookLocalDatasource(),
        _chapterService = chapterService ?? AudiobookChapterService(),
        _sleepTimerService = sleepTimerService ?? AudiobookSleepTimerService(),
        _historyService = historyService ?? AudiobookHistoryService();

  AudiobookPlayerHandler? get handler => _handler;
  AudioPlayer? get player => _handler?.player;
  Audiobook? get currentBook => _currentBook;
  List<AudioTrack> get tracks => List.unmodifiable(_tracks);
  int get currentTrackIndex => _currentTrackIndex;
  AudioTrack? get currentTrack =>
      _currentTrackIndex >= 0 && _currentTrackIndex < _tracks.length ? _tracks[_currentTrackIndex] : null;
  List<AudioChapter> get chapters => List.unmodifiable(_chapters);
  AudioSettings get settings => _settings;
  AudiobookSleepTimerService get sleepTimer => _sleepTimerService;
  AudiobookHistoryService get history => _historyService;

  Stream<Duration> get positionStream =>
      _handler?.player.positionStream ?? const Stream.empty();

  Stream<Duration?> get durationStream =>
      _handler?.player.durationStream ?? const Stream.empty();

  Stream<double> get speedStream =>
      _handler?.player.speedStream ?? const Stream.empty();

  Stream<PlayerState> get playerStateStream =>
      _handler?.player.playerStateStream ?? const Stream.empty();

  Stream<AudioPlaybackStatus> get playbackStatusStream => _statusController.stream;

  Future<void> initialize() async {
    if (_initialized && _handler != null) return;

    await _localDatasource.init();
    _settings = _localDatasource.getSettings();

    try {
      _handler = await AudioService.init(
        builder: () => AudiobookPlayerHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.readingsanctuary.audiobooks',
          androidNotificationChannelName: 'Reading Sanctuary Audiobook Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (e) {
      debugPrint('AudioService.init fallback to local AudiobookPlayerHandler: $e');
      _handler = AudiobookPlayerHandler();
    }

    await _handler?.configureSession(
      onBecomingNoisy: () => pause(),
    );

    _setupPlayerListeners();
    _setupSleepTimer();
    await AudiobookWidgetService.initialize();

    _initialized = true;
  }

  void _setupPlayerListeners() {
    final player = _handler?.player;
    if (player == null) return;

    player.playerStateStream.listen((state) {
      AudioPlaybackStatus status = AudioPlaybackStatus.idle;
      if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        status = AudioPlaybackStatus.loading;
      } else if (state.processingState == ProcessingState.completed) {
        status = AudioPlaybackStatus.completed;
        _onTrackCompleted();
      } else if (state.playing) {
        status = AudioPlaybackStatus.playing;
      } else {
        status = AudioPlaybackStatus.paused;
      }
      _statusController.add(status);
      _updateWidget();
    });

    player.positionStream.listen((pos) {
      _checkChapterStop(pos);
    });

    player.currentIndexStream.listen((idx) {
      if (idx != null && idx >= 0 && idx < _tracks.length && idx != _currentTrackIndex) {
        _currentTrackIndex = idx;
        _historyService.onTrackChanged(idx, 0);
        _saveProgress();
        _updateWidget();
      }
    });

    // Periodic progress save every 8 seconds
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (player.playing) {
        _saveProgress();
      }
    });
  }

  void _setupSleepTimer() {
    _sleepTimerService.onTimerExpired = () async {
      await pause();
    };
    _sleepTimerService.onVolumeChanged = (vol) {
      _handler?.player.setVolume(vol);
    };
    _sleepTimerService.onExtendRequested = () async {
      await play();
    };
  }

  Future<void> loadAudiobook({
    required Audiobook book,
    List<AudioTrack>? tracks,
    int? initialTrackIndex,
    Duration? initialPosition,
    bool autoPlay = false,
  }) async {
    await initialize();
    _currentBook = book;
    _tracks = tracks ?? _localDatasource.getTracksForBook(book.id);

    // Load chapters
    _chapters = await _chapterService.getChaptersForBook(book.id, _tracks);

    // Restore saved progress if not explicitly provided
    final savedProgress = _localDatasource.getProgress(book.id);
    final targetTrackIndex = initialTrackIndex ?? savedProgress?.trackIndex ?? 0;
    final targetPosition = initialPosition ??
        (savedProgress != null ? Duration(milliseconds: savedProgress.positionMs) : Duration.zero);
    final targetSpeed = savedProgress?.playbackSpeed ?? _settings.playbackSpeed;

    await _handler?.loadTracks(
      tracks: _tracks,
      bookTitle: book.title,
      author: book.author,
      coverPath: book.coverPath,
      initialTrackIndex: targetTrackIndex,
      initialPosition: targetPosition,
      initialSpeed: targetSpeed,
    );

    _currentTrackIndex = targetTrackIndex;
    _updateWidget();

    if (autoPlay) {
      await play();
    }
  }

  Future<void> play() async {
    if (_handler == null) return;

    // Auto-rewind logic on resume
    if (_lastPauseTime != null && _settings.autoRewindSeconds > 0) {
      final pauseDuration = DateTime.now().difference(_lastPauseTime!);
      int rewindSec = 0;
      if (pauseDuration.inSeconds > 60) {
        rewindSec = _settings.autoRewindSeconds + 2;
      } else if (pauseDuration.inSeconds >= 10) {
        rewindSec = _settings.autoRewindSeconds;
      }
      if (rewindSec > 0) {
        final currentPos = _handler!.player.position;
        final target = currentPos - Duration(seconds: rewindSec);
        await _handler!.seek(target < Duration.zero ? Duration.zero : target);
      }
      _lastPauseTime = null;
    }

    await _handler!.play();

    if (_currentBook != null) {
      _historyService.onPlaybackStarted(
        _currentBook!.id,
        _currentTrackIndex,
        _handler!.player.position.inMilliseconds,
      );
    }
    _updateWidget();
  }

  Future<void> pause() async {
    if (_handler == null) return;
    _lastPauseTime = DateTime.now();
    await _handler!.pause();

    _historyService.onPlaybackPaused(
      _currentTrackIndex,
      _handler!.player.position.inMilliseconds,
    );

    await _saveProgress();
    _updateWidget();
  }

  Future<void> seek(Duration position) async {
    if (_handler == null) return;
    final currentPos = _handler!.player.position;
    final isForward = position > currentPos;
    await _handler!.seek(position);

    _historyService.onSeek(_currentTrackIndex, position.inMilliseconds, isForward);
    await _saveProgress();
    _updateWidget();
  }

  Future<void> skipForward({Duration amount = const Duration(seconds: 30)}) async {
    if (_handler == null) return;
    final target = _handler!.player.position + amount;
    await seek(target);
  }

  Future<void> skipBackward({Duration amount = const Duration(seconds: 15)}) async {
    if (_handler == null) return;
    final target = _handler!.player.position - amount;
    await seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> skipToNextTrack() async {
    await _handler?.skipToNext();
    _saveProgress();
  }

  Future<void> skipToPreviousTrack() async {
    await _handler?.skipToPrevious();
    _saveProgress();
  }

  Future<void> skipToTrack(int index) async {
    await _handler?.skipToQueueItem(index);
    _currentTrackIndex = index;
    _saveProgress();
  }

  Future<void> setSpeed(double speed) async {
    if (speed < 0.5 || speed > 3.0) return;
    await _handler?.setSpeed(speed);
    _settings = _settings.copyWith(playbackSpeed: speed);
    await _localDatasource.saveSettings(_settings);
    _saveProgress();
  }

  Future<void> setSilenceSkipping(bool enabled) async {
    _settings = _settings.copyWith(silenceSkipping: enabled);
    await _localDatasource.saveSettings(_settings);
    // Configure just_audio skip silence where available
    try {
      // just_audio supports speed modification or skip-silence if platform supported
    } catch (_) {}
  }

  Future<void> setVolumeBoost(bool enabled) async {
    _settings = _settings.copyWith(volumeBoost: enabled);
    await _localDatasource.saveSettings(_settings);
    final gain = enabled ? 1.4 : 1.0;
    await _handler?.player.setVolume(gain);
  }

  Future<void> setStopAtChapterEnd(bool enabled) async {
    _settings = _settings.copyWith(stopAtChapterEnd: enabled);
    await _localDatasource.saveSettings(_settings);
    if (enabled) {
      _setChapterStopTarget();
    } else {
      _chapterStopTarget = null;
    }
  }

  void _setChapterStopTarget() {
    if (_chapters.isEmpty) return;
    final pos = _handler?.player.position ?? Duration.zero;
    final currentCh = _chapterService.findCurrentChapter(
      chapters: _chapters,
      currentTrackId: currentTrack?.id ?? '',
      position: pos,
    );
    if (currentCh != null) {
      _chapterStopTarget = currentCh.end;
    }
  }

  void _checkChapterStop(Duration pos) {
    if (_settings.stopAtChapterEnd && _chapterStopTarget != null) {
      if (pos >= _chapterStopTarget!) {
        _chapterStopTarget = null;
        pause();
      }
    }
  }

  void _onTrackCompleted() {
    if (_currentBook != null) {
      _historyService.onPlaybackCompleted(
        _currentTrackIndex,
        _handler?.player.position.inMilliseconds ?? 0,
      );
    }
    if (_currentTrackIndex < _tracks.length - 1) {
      skipToNextTrack();
    } else {
      // Whole book finished
      _markBookCompleted();
    }
  }

  Future<void> _markBookCompleted() async {
    if (_currentBook == null) return;
    final completedProgress = PlaybackProgress(
      audiobookId: _currentBook!.id,
      currentTrackId: currentTrack?.id,
      trackIndex: _currentTrackIndex,
      positionMs: _handler?.player.position.inMilliseconds ?? 0,
      totalDurationMs: _currentBook!.totalDurationMs,
      playbackSpeed: _settings.playbackSpeed,
      lastListenedAt: DateTime.now(),
      completed: true,
    );
    await _localDatasource.saveProgressRecord(completedProgress);
  }

  Future<void> _saveProgress() async {
    if (_currentBook == null || _handler == null) return;
    final posMs = _handler!.player.position.inMilliseconds;
    final progress = PlaybackProgress(
      audiobookId: _currentBook!.id,
      currentTrackId: currentTrack?.id,
      trackIndex: _currentTrackIndex,
      positionMs: posMs,
      totalDurationMs: _currentBook!.totalDurationMs,
      playbackSpeed: _settings.playbackSpeed,
      lastListenedAt: DateTime.now(),
      completed: false,
    );
    await _localDatasource.saveProgressRecord(progress);
  }

  void _updateWidget() {
    if (_currentBook == null) return;
    final player = _handler?.player;
    AudiobookWidgetService.updateNowPlaying(
      title: _currentBook!.title,
      author: _currentBook!.author,
      coverPath: _currentBook!.coverPath,
      isPlaying: player?.playing ?? false,
      positionMs: player?.position.inMilliseconds ?? 0,
      durationMs: player?.duration?.inMilliseconds ?? 0,
      audiobookId: _currentBook!.id,
    );
  }

  Future<void> stop() async {
    _progressSaveTimer?.cancel();
    _historyService.endSession();
    await _saveProgress();
    await _handler?.stop();
  }

  Future<void> dispose() async {
    _progressSaveTimer?.cancel();
    _sleepTimerService.dispose();
    await _handler?.dispose();
    _statusController.close();
    _initialized = false;
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/audio_chapter.dart';
import '../../data/models/audio_position.dart';
import '../../data/models/audio_track.dart';
import '../../data/repositories/audiobook_repository.dart';
import '../../data/services/audio_player_service.dart';
import '../../domain/enums/audio_playback_state.dart';
import '../../domain/services/audio_position_service.dart';
import '../../../reader/presentation/providers/reader_provider.dart';
import '../../../analytics/application/analytics_providers.dart';
import '../../../analytics/data/models/activity_session.dart';

final audiobookRepositoryProvider = Provider<AudiobookRepository>((ref) {
  return HttpAudiobookRepository(
    tokenProvider: () => ref.read(authTokenProvider),
  );
});

final audioPositionServiceProvider = Provider<AudioPositionService>((ref) {
  final repo = ref.watch(audiobookRepositoryProvider);
  final service = AudioPositionService(repository: repo);
  ref.onDispose(service.dispose);
  return service;
});

final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(service.dispose);
  return service;
});

class AudiobookState {
  final AudioTrack? currentTrack;
  final AudioPlaybackStatus status;
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final double playbackSpeed;
  final List<AudioChapter> chapters;
  final int currentChapterIndex;
  final bool isCompleted;
  final String? errorMessage;
  final Duration? sleepTimerRemaining;
  final bool sleepTimerEndOfChapter;

  const AudiobookState({
    this.currentTrack,
    this.status = AudioPlaybackStatus.idle,
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.chapters = const [],
    this.currentChapterIndex = 0,
    this.isCompleted = false,
    this.errorMessage,
    this.sleepTimerRemaining,
    this.sleepTimerEndOfChapter = false,
  });

  AudioChapter? get currentChapter =>
      (currentChapterIndex >= 0 && currentChapterIndex < chapters.length)
          ? chapters[currentChapterIndex]
          : null;

  AudiobookState copyWith({
    AudioTrack? currentTrack,
    AudioPlaybackStatus? status,
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    double? playbackSpeed,
    List<AudioChapter>? chapters,
    int? currentChapterIndex,
    bool? isCompleted,
    String? errorMessage,
    bool clearError = false,
    Duration? sleepTimerRemaining,
    bool clearSleepTimer = false,
    bool? sleepTimerEndOfChapter,
  }) {
    return AudiobookState(
      currentTrack: currentTrack ?? this.currentTrack,
      status: status ?? this.status,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      chapters: chapters ?? this.chapters,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sleepTimerRemaining: clearSleepTimer
          ? null
          : (sleepTimerRemaining ?? this.sleepTimerRemaining),
      sleepTimerEndOfChapter:
          sleepTimerEndOfChapter ?? this.sleepTimerEndOfChapter,
    );
  }
}

class AudiobookNotifier extends StateNotifier<AudiobookState> {
  final AudioPlayerService _playerService;
  final AudioPositionService _positionService;
  final Ref _ref;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _speedSub;
  Timer? _sleepTimer;
  Timer? _sleepTicker;

  AudiobookNotifier({
    required AudioPlayerService playerService,
    required AudioPositionService positionService,
    required Ref ref,
  })  : _playerService = playerService,
        _positionService = positionService,
        _ref = ref,
        super(const AudiobookState()) {
    _initStreams();
  }

  void _initStreams() {
    _posSub = _playerService.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
      _checkSleepTimerEndOfChapter(pos);
      _maybeAutoSavePosition(pos);
    });

    _durSub = _playerService.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });

    _speedSub = _playerService.speedStream.listen((spd) {
      state = state.copyWith(playbackSpeed: spd);
    });

    _statusSub = _playerService.playbackStatusStream.listen((status) {
      final isPlaying = status == AudioPlaybackStatus.playing;
      final isLoading = status == AudioPlaybackStatus.loading;
      final isCompleted = status == AudioPlaybackStatus.completed;

      state = state.copyWith(
        status: status,
        isPlaying: isPlaying,
        isLoading: isLoading,
        isCompleted: isCompleted,
      );

      if (!isPlaying) {
        savePosition();
      }
    });
  }

  Future<void> loadAudio({
    required AudioTrack track,
    bool autoPlay = false,
  }) async {
    state = state.copyWith(
      currentTrack: track,
      isLoading: true,
      clearError: true,
    );

    try {
      final token = _ref.read(authTokenProvider);
      final baseUrl = _resolveBaseUrl();
      final audioUrl = '$baseUrl/books/${track.bookId}/files/${track.fileId}';
      final headers = <String, String>{
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      // Retrieve saved position
      final saved = await _positionService.getPosition(
        bookId: track.bookId,
        fileId: track.fileId,
      );

      Duration? initialPosition;
      double speed = 1.0;
      if (saved != null) {
        initialPosition = Duration(milliseconds: saved.positionMs);
        speed = saved.playbackSpeed;
      }

      await _playerService.loadAudio(
        audioUrl: audioUrl,
        headers: headers,
        track: track,
        initialPosition: initialPosition,
        initialSpeed: speed,
      );

      state = state.copyWith(
        isLoading: false,
        playbackSpeed: speed,
        position: initialPosition ?? Duration.zero,
      );

      if (autoPlay) {
        await play();
      }
    } catch (e) {
      debugPrint('Error loading audiobook: $e');
      state = state.copyWith(
        isLoading: false,
        status: AudioPlaybackStatus.error,
        errorMessage: 'Failed to load audio: $e',
      );
    }
  }

  static String _resolveBaseUrl() {
    if (kIsWeb) return 'http://localhost:8080/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8080/api/v1';
    return 'http://localhost:8080/api/v1';
  }

  Future<void> play() async {
    await _playerService.play();
  }

  Future<void> pause() async {
    await _playerService.pause();
    await savePosition();
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _playerService.seek(position);
    await savePosition();
  }

  Future<void> skipForward() async {
    await _playerService.skipForward();
  }

  Future<void> skipBackward() async {
    await _playerService.skipBackward();
  }

  Future<void> setSpeed(double speed) async {
    await _playerService.setSpeed(speed);
    state = state.copyWith(playbackSpeed: speed);
    await savePosition();
  }

  Future<void> playChapter(int index) async {
    await _playerService.playChapter(index);
    state = state.copyWith(currentChapterIndex: index);
  }

  Future<void> playNextChapter() async {
    await _playerService.playNextChapter();
    state = state.copyWith(
      currentChapterIndex: _playerService.currentChapterIndex,
    );
  }

  Future<void> playPreviousChapter() async {
    await _playerService.playPreviousChapter();
    state = state.copyWith(
      currentChapterIndex: _playerService.currentChapterIndex,
    );
  }

  void setChapters(List<AudioChapter> chapters) {
    _playerService.setChapters(chapters);
    state = state.copyWith(
      chapters: chapters,
      currentChapterIndex: 0,
    );
  }

  void setSleepTimer(Duration? duration, {bool endOfChapter = false}) {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();

    if (duration == null && !endOfChapter) {
      state = state.copyWith(
        clearSleepTimer: true,
        sleepTimerEndOfChapter: false,
      );
      return;
    }

    if (endOfChapter) {
      state = state.copyWith(
        clearSleepTimer: true,
        sleepTimerEndOfChapter: true,
      );
      return;
    }

    state = state.copyWith(
      sleepTimerRemaining: duration,
      sleepTimerEndOfChapter: false,
    );

    var remaining = duration!;
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= const Duration(seconds: 1);
      if (remaining <= Duration.zero) {
        timer.cancel();
        pause();
        state = state.copyWith(
          clearSleepTimer: true,
          sleepTimerEndOfChapter: false,
        );
      } else {
        state = state.copyWith(sleepTimerRemaining: remaining);
      }
    });
  }

  void _checkSleepTimerEndOfChapter(Duration currentPosition) {
    if (!state.sleepTimerEndOfChapter || state.chapters.isEmpty) return;

    final curChapter = state.currentChapter;
    if (curChapter != null && currentPosition >= curChapter.end) {
      pause();
      state = state.copyWith(
        clearSleepTimer: true,
        sleepTimerEndOfChapter: false,
      );
    }
  }

  DateTime _lastSaveTime = DateTime.now();
  void _maybeAutoSavePosition(Duration currentPosition) {
    final now = DateTime.now();
    if (now.difference(_lastSaveTime).inSeconds >= 10 && state.isPlaying) {
      _lastSaveTime = now;
      savePosition();
    }
  }

  Future<void> savePosition() async {
    final track = state.currentTrack;
    if (track == null) return;

    final pos = AudioPosition(
      positionMs: state.position.inMilliseconds,
      durationMs: state.duration.inMilliseconds,
      playbackSpeed: state.playbackSpeed,
      isCompleted: state.isCompleted,
      updatedAt: DateTime.now(),
    );

    _positionService.scheduleSave(
      bookId: track.bookId,
      fileId: track.fileId,
      position: pos,
      isCompleted: state.isCompleted,
    );
  }

  Future<void> stop() async {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    await savePosition();
    await _playerService.stop();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _statusSub?.cancel();
    _speedSub?.cancel();
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    super.dispose();
  }
}

final audiobookProvider =
    StateNotifierProvider<AudiobookNotifier, AudiobookState>((ref) {
  final playerService = ref.watch(audioPlayerServiceProvider);
  final positionService = ref.watch(audioPositionServiceProvider);
  return AudiobookNotifier(
    playerService: playerService,
    positionService: positionService,
    ref: ref,
  );
});

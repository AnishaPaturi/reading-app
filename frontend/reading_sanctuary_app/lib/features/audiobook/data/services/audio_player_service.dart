import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audio_chapter.dart';
import '../models/audio_track.dart';
import '../../domain/enums/audio_playback_state.dart';
import 'audio_background_handler.dart';

class AudioPlayerService {
  AudioBackgroundHandler? _handler;
  bool _initialized = false;
  AudioTrack? _currentTrack;
  List<AudioChapter> _chapters = [];
  int _currentChapterIndex = 0;

  AudioBackgroundHandler? get handler => _handler;
  AudioPlayer? get player => _handler?.player;
  AudioTrack? get currentTrack => _currentTrack;
  List<AudioChapter> get chapters => List.unmodifiable(_chapters);
  int get currentChapterIndex => _currentChapterIndex;

  Stream<Duration> get positionStream =>
      _handler?.player.positionStream ?? const Stream.empty();

  Stream<Duration?> get durationStream =>
      _handler?.player.durationStream ?? const Stream.empty();

  Stream<double> get speedStream =>
      _handler?.player.speedStream ?? const Stream.empty();

  Stream<PlayerState> get playerStateStream =>
      _handler?.player.playerStateStream ?? const Stream.empty();

  Stream<AudioPlaybackStatus> get playbackStatusStream {
    final player = _handler?.player;
    if (player == null) return Stream.value(AudioPlaybackStatus.idle);

    return player.playerStateStream.map((state) {
      if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        return AudioPlaybackStatus.loading;
      }
      if (state.processingState == ProcessingState.completed) {
        return AudioPlaybackStatus.completed;
      }
      if (state.playing) {
        return AudioPlaybackStatus.playing;
      }
      return AudioPlaybackStatus.paused;
    });
  }

  Future<void> initialize() async {
    if (_initialized && _handler != null) return;

    try {
      _handler = await AudioService.init(
        builder: () => AudioBackgroundHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.readingsanctuary.audio',
          androidNotificationChannelName: 'Reading Sanctuary Audio Playback',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );
    } catch (e) {
      debugPrint('AudioService.init fallback to local handler: $e');
      _handler = AudioBackgroundHandler();
    }

    await _handler?.configureSession();
    _initialized = true;
  }

  Future<void> loadAudio({
    required String audioUrl,
    required Map<String, String> headers,
    required AudioTrack track,
    Duration? initialPosition,
    double initialSpeed = 1.0,
  }) async {
    await initialize();
    _currentTrack = track;

    _handler?.updateMediaMetadata(
      id: track.fileId,
      title: track.title,
      author: track.author,
      coverUrl: track.coverUrl,
    );

    final player = _handler?.player;
    if (player == null) return;

    await player.setAudioSource(
      AudioSource.uri(
        Uri.parse(audioUrl),
        headers: headers,
      ),
      initialPosition: initialPosition,
    );

    if (initialSpeed != 1.0) {
      await player.setSpeed(initialSpeed);
    }
  }

  void setChapters(List<AudioChapter> chapters) {
    _chapters = List.from(chapters);
    _currentChapterIndex = 0;
  }

  Future<void> play() async {
    await _handler?.play();
  }

  Future<void> pause() async {
    await _handler?.pause();
  }

  Future<void> seek(Duration position) async {
    await _handler?.seek(position);
    _updateCurrentChapter(position);
  }

  Future<void> setSpeed(double speed) async {
    await _handler?.setSpeed(speed);
  }

  Future<void> skipForward() async {
    await _handler?.fastForward();
    final pos = _handler?.player.position;
    if (pos != null) _updateCurrentChapter(pos);
  }

  Future<void> skipBackward() async {
    await _handler?.rewind();
    final pos = _handler?.player.position;
    if (pos != null) _updateCurrentChapter(pos);
  }

  Future<void> playChapter(int index) async {
    if (index >= 0 && index < _chapters.length) {
      _currentChapterIndex = index;
      await seek(_chapters[index].start);
      await play();
    }
  }

  Future<void> playNextChapter() async {
    if (_currentChapterIndex + 1 < _chapters.length) {
      await playChapter(_currentChapterIndex + 1);
    }
  }

  Future<void> playPreviousChapter() async {
    if (_currentChapterIndex > 0) {
      await playChapter(_currentChapterIndex - 1);
    }
  }

  void _updateCurrentChapter(Duration position) {
    if (_chapters.isEmpty) return;
    for (var i = 0; i < _chapters.length; i++) {
      if (position >= _chapters[i].start && position < _chapters[i].end) {
        _currentChapterIndex = i;
        break;
      }
    }
  }

  Future<void> stop() async {
    await _handler?.stop();
  }

  Future<void> dispose() async {
    await _handler?.dispose();
    _initialized = false;
  }
}

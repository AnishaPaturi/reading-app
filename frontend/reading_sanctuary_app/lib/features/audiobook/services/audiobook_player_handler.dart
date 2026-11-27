import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../data/models/audio_track.dart';

class AudiobookPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;
  List<AudioTrack> _tracks = [];
  int _currentTrackIndex = 0;

  AudiobookPlayerHandler({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _initStreams();
  }

  AudioPlayer get player => _player;
  List<AudioTrack> get tracks => List.unmodifiable(_tracks);
  int get currentTrackIndex => _currentTrackIndex;

  void _initStreams() {
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      final hasNext = _player.hasNext || _currentTrackIndex < _tracks.length - 1;
      final hasPrev = _player.hasPrevious || _currentTrackIndex > 0;

      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (hasPrev) MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          if (hasNext) MediaControl.skipToNext,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        },
        androidCompactActionIndices: const [0, 2, 4],
        processingState: _mapProcessingState(_player.processingState),
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex ?? _currentTrackIndex,
      ));
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _tracks.length) {
        _currentTrackIndex = index;
        _updateMediaItemForCurrentTrack();
      }
    });

    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });
  }

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  Future<void> configureSession({
    VoidCallback? onBecomingNoisy,
    void Function(bool begin, AudioInterruptionType type)? onInterruption,
  }) async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      session.interruptionEventStream.listen((event) {
        if (onInterruption != null) {
          onInterruption(event.begin, event.type);
        } else {
          if (event.begin) {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _player.setVolume(0.5);
                break;
              case AudioInterruptionType.pause:
              case AudioInterruptionType.unknown:
                pause();
                break;
            }
          } else {
            switch (event.type) {
              case AudioInterruptionType.duck:
                _player.setVolume(1.0);
                break;
              case AudioInterruptionType.pause:
                play();
                break;
              case AudioInterruptionType.unknown:
                break;
            }
          }
        }
      });

      session.becomingNoisyEventStream.listen((_) {
        if (onBecomingNoisy != null) {
          onBecomingNoisy();
        } else {
          pause();
        }
      });
    } catch (e) {
      debugPrint('AudioSession configuration notice: $e');
    }
  }

  Future<void> loadTracks({
    required List<AudioTrack> tracks,
    required String bookTitle,
    required String author,
    String? coverPath,
    int initialTrackIndex = 0,
    Duration initialPosition = Duration.zero,
    double initialSpeed = 1.0,
  }) async {
    _tracks = List.from(tracks);
    _currentTrackIndex = initialTrackIndex.clamp(0, tracks.isEmpty ? 0 : tracks.length - 1);

    if (tracks.isEmpty) return;

    final audioSources = <AudioSource>[];
    final mediaItems = <MediaItem>[];
    for (var i = 0; i < tracks.length; i++) {
      final t = tracks[i];
      final tag = MediaItem(
        id: t.id,
        album: bookTitle,
        title: t.chapterTitle ?? t.fileName,
        artist: author,
        artUri: coverPath != null
            ? (coverPath.startsWith('http')
                ? Uri.tryParse(coverPath)
                : (kIsWeb ? null : Uri.file(coverPath)))
            : null,
      );
      mediaItems.add(tag);

      if (t.filePath.startsWith('http://') ||
          t.filePath.startsWith('https://') ||
          kIsWeb) {
        audioSources.add(AudioSource.uri(Uri.parse(t.filePath), tag: tag));
      } else {
        audioSources.add(AudioSource.file(t.filePath, tag: tag));
      }
    }

    queue.add(mediaItems);

    await _player.setAudioSources(
      audioSources,
      initialIndex: _currentTrackIndex,
      initialPosition: initialPosition,
    );

    if (initialSpeed != 1.0) {
      await _player.setSpeed(initialSpeed);
    }

    _updateMediaItemForCurrentTrack();
  }

  void _updateMediaItemForCurrentTrack() {
    if (_currentTrackIndex >= 0 && _currentTrackIndex < _tracks.length) {
      final t = _tracks[_currentTrackIndex];
      final previous = mediaItem.value;
      mediaItem.add(MediaItem(
        id: t.id,
        album: previous?.album ?? 'Audiobook',
        title: t.chapterTitle ?? t.fileName,
        artist: t.author ?? previous?.artist ?? 'Unknown Author',
        artUri: previous?.artUri,
        duration: t.durationMs > 0
            ? Duration(milliseconds: t.durationMs)
            : _player.duration,
      ));
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_currentTrackIndex < _tracks.length - 1) {
      await skipToQueueItem(_currentTrackIndex + 1);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_currentTrackIndex > 0) {
      await skipToQueueItem(_currentTrackIndex - 1);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _tracks.length) {
      _currentTrackIndex = index;
      await _player.seek(Duration.zero, index: index);
      _updateMediaItemForCurrentTrack();
    }
  }

  @override
  Future<void> fastForward() async {
    final target = _player.position + const Duration(seconds: 30);
    final duration = _player.duration;
    if (duration != null && target > duration) {
      await seek(duration);
    } else {
      await seek(target);
    }
  }

  @override
  Future<void> rewind() async {
    final target = _player.position - const Duration(seconds: 15);
    await seek(target < Duration.zero ? Duration.zero : target);
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

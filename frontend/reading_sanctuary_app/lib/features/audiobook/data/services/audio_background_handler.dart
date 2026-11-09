import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioBackgroundHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player;

  AudioBackgroundHandler({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _initStreams();
  }

  AudioPlayer get player => _player;

  void _initStreams() {
    // Broadcast player state changes to audio_service playbackState
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });

    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem != null && duration != null) {
        mediaItem.add(currentItem.copyWith(duration: duration));
      }
    });
  }

  Future<void> configureSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());

      session.interruptionEventStream.listen((event) {
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
      });

      session.becomingNoisyEventStream.listen((_) {
        pause();
      });
    } catch (e) {
      debugPrint('AudioSession configuration notice: $e');
    }
  }

  void updateMediaMetadata({
    required String id,
    required String title,
    String? author,
    String? coverUrl,
    Duration? duration,
  }) {
    mediaItem.add(MediaItem(
      id: id,
      album: author ?? 'Reading Sanctuary',
      title: title,
      artist: author,
      artUri: coverUrl != null ? Uri.tryParse(coverUrl) : null,
      duration: duration ?? _player.duration,
    ));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

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

  Future<void> dispose() async {
    await _player.dispose();
  }
}

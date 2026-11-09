import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsProgress {
  final String text;
  final int start;
  final int end;
  final String word;

  const TtsProgress({
    required this.text,
    required this.start,
    required this.end,
    required this.word,
  });
}

class TtsService {
  final FlutterTts _tts;
  VoidCallback? onComplete;
  VoidCallback? onStart;
  ValueChanged<TtsProgress>? onProgress;
  ValueChanged<String>? onError;

  TtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _initCallbacks();
  }

  void _initCallbacks() {
    _tts.setStartHandler(() {
      onStart?.call();
    });

    _tts.setCompletionHandler(() {
      onComplete?.call();
    });

    _tts.setProgressHandler((text, start, end, word) {
      onProgress?.call(TtsProgress(
        text: text,
        start: start,
        end: end,
        word: word,
      ));
    });

    _tts.setErrorHandler((dynamic message) {
      onError?.call(message.toString());
    });
  }

  Future<void> initialize() async {
    try {
      await _tts.setSpeechRate(0.5); // 0.5 default on Android/iOS is standard normal speed
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint('TtsService init warning: $e');
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _tts.speak(text);
  }

  Future<void> pause() async {
    await _tts.pause();
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> setSpeechRate(double rate) async {
    // Convert 0.5 - 2.0 UI rate to flutter_tts rate
    // On iOS, 0.5 is normal speed. On Android, 1.0 is normal speed (or mapped).
    await _tts.setSpeechRate(rate);
  }

  Future<void> setPitch(double pitch) async {
    await _tts.setPitch(pitch);
  }

  Future<List<Map<String, String>>> getVoices() async {
    try {
      final dynamic raw = await _tts.getVoices;
      if (raw is List) {
        final result = <Map<String, String>>[];
        for (final item in raw) {
          if (item is Map) {
            result.add({
              'name': item['name']?.toString() ?? '',
              'locale': item['locale']?.toString() ?? '',
            });
          }
        }
        return result;
      }
    } catch (e) {
      debugPrint('Error getting TTS voices: $e');
    }
    return [];
  }

  Future<void> setVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}

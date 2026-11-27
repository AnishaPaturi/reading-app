import 'package:flutter/foundation.dart';
import 'audio_metadata_result.dart';

class AudiobookMetadataService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<AudioMetadataResult> readMetadata(String filePath) async {
    await initialize();
    try {
      final cleanName = filePath.split(RegExp(r'[/\\]')).last;
      final nameWithoutExt = cleanName.contains('.')
          ? cleanName.substring(0, cleanName.lastIndexOf('.'))
          : cleanName;
      return AudioMetadataResult(
        title: nameWithoutExt,
      );
    } catch (e) {
      debugPrint('Error reading web metadata for $filePath: $e');
      return const AudioMetadataResult();
    }
  }
}

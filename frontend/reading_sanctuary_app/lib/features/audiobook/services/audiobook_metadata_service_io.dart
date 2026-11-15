import 'package:flutter/foundation.dart';
import 'package:metadata_god/metadata_god.dart';
import 'audio_metadata_result.dart';

class AudiobookMetadataService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MetadataGod.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('MetadataGod init exception: $e');
    }
  }

  Future<AudioMetadataResult> readMetadata(String filePath) async {
    await initialize();
    try {
      final metadata = await MetadataGod.readMetadata(file: filePath);
      return AudioMetadataResult(
        title: metadata.title,
        artist: metadata.artist ?? metadata.albumArtist,
        album: metadata.album,
        trackNumber: metadata.trackNumber,
        durationMs: metadata.durationMs?.toInt(),
        pictureBytes: metadata.picture?.data,
        mimeType: metadata.picture?.mimeType,
      );
    } catch (e) {
      debugPrint('Error reading metadata for $filePath: $e');
      return const AudioMetadataResult();
    }
  }
}

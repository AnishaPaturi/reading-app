import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as amr;
import 'package:flutter/foundation.dart';
import 'audio_metadata_result.dart';

/// IO implementation of [AudiobookMetadataService] using pure-Dart audio tag parsing.
class AudiobookMetadataService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<AudioMetadataResult> readMetadata(String filePath) async {
    await initialize();
    try {
      final metadata = amr.readMetadata(File(filePath), getImage: true);
      amr.Picture? cover;
      for (final pic in metadata.pictures) {
        if (pic.pictureType == amr.PictureType.coverFront) {
          cover = pic;
          break;
        }
      }
      cover ??= metadata.pictures.isNotEmpty ? metadata.pictures.first : null;
      return AudioMetadataResult(
        title: metadata.title,
        artist: metadata.artist,
        albumArtist: metadata.albumArtist,
        album: metadata.album,
        trackNumber: metadata.trackNumber,
        trackTotal: metadata.trackTotal,
        discNumber: metadata.discNumber,
        discTotal: metadata.totalDisc,
        durationMs: metadata.duration?.inMilliseconds,
        pictureBytes: cover?.bytes,
        mimeType: cover?.mimetype,
      );
    } catch (e) {
      debugPrint('Error reading metadata for $filePath: $e');
      return const AudioMetadataResult();
    }
  }
}

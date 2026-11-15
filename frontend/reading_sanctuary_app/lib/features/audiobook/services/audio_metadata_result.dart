import 'dart:typed_data';

class AudioMetadataResult {
  final String? title;
  final String? artist;
  final String? album;
  final String? narrator;
  final int? trackNumber;
  final int? durationMs;
  final Uint8List? pictureBytes;
  final String? mimeType;

  const AudioMetadataResult({
    this.title,
    this.artist,
    this.album,
    this.narrator,
    this.trackNumber,
    this.durationMs,
    this.pictureBytes,
    this.mimeType,
  });
}

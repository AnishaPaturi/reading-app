import 'dart:typed_data';

class AudioMetadataResult {
  final String? title;
  final String? artist;
  final String? albumArtist;
  final String? album;
  final String? narrator;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? discTotal;
  final int? durationMs;
  final Uint8List? pictureBytes;
  final String? mimeType;

  const AudioMetadataResult({
    this.title,
    this.artist,
    this.albumArtist,
    this.album,
    this.narrator,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.discTotal,
    this.durationMs,
    this.pictureBytes,
    this.mimeType,
  });
}

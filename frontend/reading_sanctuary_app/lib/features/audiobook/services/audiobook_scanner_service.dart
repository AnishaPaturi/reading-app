import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/audiobook.dart';
import '../data/models/audio_track.dart';
import '../utils/audio_format_utils.dart';
import '../utils/audiobook_grouping_utils.dart';
import 'audiobook_metadata_service.dart';
import 'audiobook_artwork_service.dart';

class DiscoveredBook {
  String id;
  String title;
  String author;
  String? narrator;
  String? description;
  String? coverPath;
  String? folderPath;
  List<AudioTrack> tracks;
  int totalDurationMs;

  DiscoveredBook({
    required this.id,
    required this.title,
    required this.author,
    this.narrator,
    this.description,
    this.coverPath,
    this.folderPath,
    required this.tracks,
    required this.totalDurationMs,
  });

  Audiobook toAudiobook() {
    return Audiobook(
      id: id,
      title: title,
      author: author,
      narrator: narrator,
      description: description,
      coverPath: coverPath,
      folderPath: folderPath,
      totalDurationMs: totalDurationMs,
      totalTracks: tracks.length,
      status: AudiobookStatus.notStarted,
      dateAdded: DateTime.now(),
    );
  }
}

class AudiobookScannerService {
  final AudiobookMetadataService _metadataService;
  final AudiobookArtworkService _artworkService;
  final Uuid _uuid = const Uuid();

  AudiobookScannerService({
    AudiobookMetadataService? metadataService,
    AudiobookArtworkService? artworkService,
  })  : _metadataService = metadataService ?? AudiobookMetadataService(),
        _artworkService = artworkService ?? AudiobookArtworkService();

  /// Scans a folder recursively, finds supported audio files, extracts metadata and groups into DiscoveredBooks
  Future<List<DiscoveredBook>> scanFolder(String folderPath) async {
    final rootDir = Directory(folderPath);
    if (!await rootDir.exists()) {
      throw Exception('Selected folder does not exist.');
    }

    final audioFiles = <File>[];
    await for (final entity in rootDir.list(recursive: true, followLinks: false)) {
      if (entity is File && AudioFormatUtils.isSupported(entity.path)) {
        audioFiles.add(entity);
      }
    }

    if (audioFiles.isEmpty) {
      return [];
    }

    // Natural sort audio files
    audioFiles.sort((a, b) => AudiobookGroupingUtils.naturalCompare(a.path, b.path));

    // Group files by parent directory (Priority 1)
    final filesByFolder = <String, List<File>>{};
    for (final file in audioFiles) {
      final parentDir = file.parent.path;
      filesByFolder.putIfAbsent(parentDir, () => []).add(file);
    }

    final discoveredBooks = <DiscoveredBook>[];

    for (final entry in filesByFolder.entries) {
      final folder = entry.key;
      final files = entry.value;

      final bookId = _uuid.v4();
      final tracks = <AudioTrack>[];
      int totalDurationMs = 0;
      String? detectedAlbum;
      String? detectedArtist;
      String? detectedNarrator;
      String? embeddedCoverPath;

      // Check local folder for cover image
      String? coverPath = await _artworkService.findLocalCover(folder);

      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final meta = await _metadataService.readMetadata(file.path);
        final fileName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'Track ${i + 1}';
        final trackTitle = meta.title ?? AudiobookGroupingUtils.cleanTrackTitle(fileName);
        final trackDuration = meta.durationMs ?? 0;
        totalDurationMs += trackDuration;

        if (detectedAlbum == null && meta.album != null && meta.album!.trim().isNotEmpty) {
          detectedAlbum = meta.album!.trim();
        }
        if (detectedArtist == null && meta.artist != null && meta.artist!.trim().isNotEmpty) {
          detectedArtist = meta.artist!.trim();
        }
        if (detectedNarrator == null && meta.narrator != null && meta.narrator!.trim().isNotEmpty) {
          detectedNarrator = meta.narrator!.trim();
        }

        // If no local cover yet, see if embedded picture is found
        if (coverPath == null && embeddedCoverPath == null && meta.pictureBytes != null) {
          embeddedCoverPath = await _artworkService.saveEmbeddedArtwork(
            meta.pictureBytes!,
            extension: meta.mimeType?.contains('png') == true ? 'png' : 'jpg',
          );
        }

        final ext = AudioFormatUtils.getExtension(file.path).toUpperCase();
        tracks.add(AudioTrack(
          id: _uuid.v4(),
          audiobookId: bookId,
          filePath: file.path,
          fileName: fileName,
          chapterTitle: trackTitle,
          trackOrder: meta.trackNumber ?? (i + 1),
          durationMs: trackDuration,
          format: ext.isEmpty ? 'AUDIO' : ext,
          fileSizeBytes: await file.length(),
          author: meta.artist ?? detectedArtist,
        ));
      }

      // Sort tracks by trackOrder then natural fileName
      tracks.sort((a, b) {
        final orderCmp = a.trackOrder.compareTo(b.trackOrder);
        if (orderCmp != 0) return orderCmp;
        return AudiobookGroupingUtils.naturalCompare(a.fileName, b.fileName);
      });

      // Normalize trackOrder 1..N
      for (var i = 0; i < tracks.length; i++) {
        tracks[i] = tracks[i].copyWith(trackOrder: i + 1);
      }

      // Determine book title:
      // Priority: detectedAlbum -> folder name -> first track title
      final folderName = Directory(folder).uri.pathSegments
          .where((s) => s.isNotEmpty)
          .lastOrNull ?? 'Audiobook';
      final bookTitle = detectedAlbum ?? (folderName == 'audiobooks' ? tracks.first.title : folderName);
      final author = detectedArtist ?? 'Unknown Author';

      discoveredBooks.add(DiscoveredBook(
        id: bookId,
        title: bookTitle,
        author: author,
        narrator: detectedNarrator,
        coverPath: coverPath ?? embeddedCoverPath,
        folderPath: folder,
        tracks: tracks,
        totalDurationMs: totalDurationMs,
      ));
    }

    return discoveredBooks;
  }

  /// Groups loose picked files into one or multiple DiscoveredBooks
  Future<List<DiscoveredBook>> processPickedFiles(List<File> files) async {
    if (files.isEmpty) return [];

    // Sort naturally
    files.sort((a, b) => AudiobookGroupingUtils.naturalCompare(a.path, b.path));

    // Group by common album tag or directory
    final grouped = <String, List<File>>{};
    final metadataMap = <String, AudioMetadataResult>{};

    for (final file in files) {
      final meta = await _metadataService.readMetadata(file.path);
      metadataMap[file.path] = meta;
      final groupKey = meta.album?.trim().isNotEmpty == true
          ? meta.album!.trim()
          : file.parent.path;
      grouped.putIfAbsent(groupKey, () => []).add(file);
    }

    final results = <DiscoveredBook>[];

    for (final entry in grouped.entries) {
      final bookFiles = entry.value;
      final bookId = _uuid.v4();
      final tracks = <AudioTrack>[];
      int totalDurationMs = 0;
      String? detectedAlbum;
      String? detectedArtist;
      String? detectedNarrator;
      String? coverPath;

      for (var i = 0; i < bookFiles.length; i++) {
        final file = bookFiles[i];
        final meta = metadataMap[file.path] ?? const AudioMetadataResult();
        final fileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'Track ${i + 1}';
        final trackTitle = meta.title ?? AudiobookGroupingUtils.cleanTrackTitle(fileName);
        final trackDuration = meta.durationMs ?? 0;
        totalDurationMs += trackDuration;

        if (detectedAlbum == null && meta.album != null && meta.album!.trim().isNotEmpty) {
          detectedAlbum = meta.album!.trim();
        }
        if (detectedArtist == null && meta.artist != null && meta.artist!.trim().isNotEmpty) {
          detectedArtist = meta.artist!.trim();
        }
        if (detectedNarrator == null && meta.narrator != null && meta.narrator!.trim().isNotEmpty) {
          detectedNarrator = meta.narrator!.trim();
        }

        if (coverPath == null && meta.pictureBytes != null) {
          coverPath = await _artworkService.saveEmbeddedArtwork(
            meta.pictureBytes!,
            extension: meta.mimeType?.contains('png') == true ? 'png' : 'jpg',
          );
        }

        final ext = AudioFormatUtils.getExtension(file.path).toUpperCase();
        tracks.add(AudioTrack(
          id: _uuid.v4(),
          audiobookId: bookId,
          filePath: file.path,
          fileName: fileName,
          chapterTitle: trackTitle,
          trackOrder: meta.trackNumber ?? (i + 1),
          durationMs: trackDuration,
          format: ext.isEmpty ? 'AUDIO' : ext,
          fileSizeBytes: await file.length(),
          author: meta.artist ?? detectedArtist,
        ));
      }

      // Check folder for cover image if not yet found
      if (coverPath == null && bookFiles.isNotEmpty) {
        coverPath = await _artworkService.findLocalCover(bookFiles.first.parent.path);
      }

      tracks.sort((a, b) {
        final orderCmp = a.trackOrder.compareTo(b.trackOrder);
        if (orderCmp != 0) return orderCmp;
        return AudiobookGroupingUtils.naturalCompare(a.fileName, b.fileName);
      });

      for (var i = 0; i < tracks.length; i++) {
        tracks[i] = tracks[i].copyWith(trackOrder: i + 1);
      }

      final fallbackTitle = bookFiles.first.parent.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .lastOrNull ?? 'Imported Audiobook';
      final bookTitle = detectedAlbum ?? (tracks.length == 1 ? tracks.first.title : fallbackTitle);

      results.add(DiscoveredBook(
        id: bookId,
        title: bookTitle,
        author: detectedArtist ?? 'Unknown Author',
        narrator: detectedNarrator,
        coverPath: coverPath,
        folderPath: bookFiles.first.parent.path,
        tracks: tracks,
        totalDurationMs: totalDurationMs,
      ));
    }

    return results;
  }
}

import 'dart:collection';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../data/models/audiobook.dart';
import '../data/models/audio_track.dart';
import '../utils/audio_format_utils.dart';
import '../utils/audiobook_grouping_utils.dart';
import 'audiobook_metadata_service.dart';
import 'audiobook_artwork_service.dart';

enum RejectedFileReason {
  unsupportedFormat,
  inaccessible,
  emptyFile,
  unreadable,
}

class RejectedAudioFile {
  final String fileName;
  final String filePath;
  final RejectedFileReason reason;
  final String? details;

  const RejectedAudioFile({
    required this.fileName,
    required this.filePath,
    required this.reason,
    this.details,
  });

  String get reasonLabel {
    switch (reason) {
      case RejectedFileReason.unsupportedFormat:
        final ext = filePath.contains('.') ? filePath.split('.').last.toUpperCase() : 'UNKNOWN';
        return 'Unsupported format ($ext)';
      case RejectedFileReason.emptyFile:
        return 'Empty file (0 bytes)';
      case RejectedFileReason.inaccessible:
        return 'File inaccessible';
      case RejectedFileReason.unreadable:
        return details != null && details!.isNotEmpty
            ? 'Unreadable: $details'
            : 'Unreadable audio data';
    }
  }

  @override
  String toString() => 'RejectedAudioFile($fileName, reason: $reason, details: $details)';
}

class AudiobookScanResult extends ListBase<DiscoveredBook> {
  final List<DiscoveredBook> books;
  final List<RejectedAudioFile> rejectedFiles;

  AudiobookScanResult({
    List<DiscoveredBook>? books,
    List<RejectedAudioFile>? rejectedFiles,
  })  : books = books != null ? List<DiscoveredBook>.from(books) : [],
        rejectedFiles = rejectedFiles != null ? List<RejectedAudioFile>.from(rejectedFiles) : [];

  @override
  int get length => books.length;

  @override
  set length(int newLength) => books.length = newLength;

  @override
  DiscoveredBook operator [](int index) => books[index];

  @override
  void operator []=(int index, DiscoveredBook value) => books[index] = value;

  bool get hasRejectedFiles => rejectedFiles.isNotEmpty;
  bool get hasBooks => books.isNotEmpty;
  int get totalTracks => books.fold(0, (sum, b) => sum + b.tracks.length);
}

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

  /// Checks whether a filename matches common local cover/artwork patterns so it is not treated as a rejected audio file
  static bool isCoverImage(String fileName) {
    final lower = fileName.toLowerCase();
    const exactCoverNames = {
      'cover.jpg',
      'cover.png',
      'cover.jpeg',
      'cover.webp',
      'folder.jpg',
      'folder.png',
      'folder.jpeg',
      'front.jpg',
      'front.png',
      'front.jpeg',
      'artwork.jpg',
      'artwork.png',
      'artwork.jpeg',
      'albumartsmall.jpg',
      'albumart.jpg',
    };
    if (exactCoverNames.contains(lower)) return true;

    final dotIndex = lower.lastIndexOf('.');
    if (dotIndex <= 0) return false;
    final base = lower.substring(0, dotIndex);
    final ext = lower.substring(dotIndex);
    const imageExts = {'.jpg', '.jpeg', '.png', '.webp'};
    if (imageExts.contains(ext) &&
        (base == 'cover' || base == 'folder' || base == 'front' || base == 'artwork' || base == 'poster')) {
      return true;
    }
    return false;
  }

  /// Scans a folder recursively, finds supported audio files, extracts metadata and groups into DiscoveredBooks
  Future<AudiobookScanResult> scanFolder(String folderPath) async {
    final rootDir = Directory(folderPath);
    if (!await rootDir.exists()) {
      throw Exception('Selected folder does not exist.');
    }

    final audioFiles = <File>[];
    final rejectedFiles = <RejectedAudioFile>[];

    await for (final entity in rootDir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      final fileName = entity.uri.pathSegments.isNotEmpty
          ? entity.uri.pathSegments.last
          : entity.path.split(Platform.pathSeparator).last;

      // Ignore common OS metadata / temporary files
      if (fileName.startsWith('.') ||
          fileName.toLowerCase() == 'thumbs.db' ||
          fileName.toLowerCase() == 'desktop.ini') {
        continue;
      }

      // If it is a known cover image, ignore it from audio rejection
      if (isCoverImage(fileName)) {
        continue;
      }

      // Check file accessibility & existence
      try {
        if (!await entity.exists()) {
          rejectedFiles.add(RejectedAudioFile(
            fileName: fileName,
            filePath: entity.path,
            reason: RejectedFileReason.inaccessible,
          ));
          continue;
        }

        final length = await entity.length();
        if (length == 0) {
          rejectedFiles.add(RejectedAudioFile(
            fileName: fileName,
            filePath: entity.path,
            reason: RejectedFileReason.emptyFile,
          ));
          continue;
        }
      } catch (e) {
        rejectedFiles.add(RejectedAudioFile(
          fileName: fileName,
          filePath: entity.path,
          reason: RejectedFileReason.inaccessible,
          details: e.toString(),
        ));
        continue;
      }

      // Check supported audio format
      if (!AudioFormatUtils.isSupported(entity.path)) {
        rejectedFiles.add(RejectedAudioFile(
          fileName: fileName,
          filePath: entity.path,
          reason: RejectedFileReason.unsupportedFormat,
        ));
        continue;
      }

      audioFiles.add(entity);
    }

    if (audioFiles.isEmpty) {
      return AudiobookScanResult(books: [], rejectedFiles: rejectedFiles);
    }

    // Natural sort audio files
    audioFiles.sort((a, b) => AudiobookGroupingUtils.naturalCompare(a.path, b.path));

    // Cache metadata once for all scanned files, isolating unreadable files
    final metadataMap = <String, AudioMetadataResult>{};
    final validAudioFiles = <File>[];

    for (final file in audioFiles) {
      try {
        metadataMap[file.path] = await _metadataService.readMetadata(file.path);
        validAudioFiles.add(file);
      } catch (e) {
        final fileName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : file.path.split(Platform.pathSeparator).last;
        rejectedFiles.add(RejectedAudioFile(
          fileName: fileName,
          filePath: file.path,
          reason: RejectedFileReason.unreadable,
          details: e.toString(),
        ));
      }
    }

    if (validAudioFiles.isEmpty) {
      return AudiobookScanResult(books: [], rejectedFiles: rejectedFiles);
    }

    // Group files by resolved book directory (or album if files in rootDir share distinct album)
    final filesByGroupKey = <String, List<File>>{};
    final groupFolderMap = <String, String>{};

    for (final file in validAudioFiles) {
      final meta = metadataMap[file.path] ?? const AudioMetadataResult();
      final resolvedBookDir = AudiobookGroupingUtils.resolveBookDirectory(file.parent, rootDir: rootDir);
      final isDirectlyInRoot = file.parent.path == rootDir.path;

      final album = meta.album?.trim();
      final artist = meta.artist?.trim() ?? '';
      final isGenericAlbum = album == null ||
          album.isEmpty ||
          RegExp(r'^(?:audiobook|audio|unknown|music|disc|cd|track)$', caseSensitive: false)
              .hasMatch(album);

      final String groupKey;
      if (isDirectlyInRoot && !isGenericAlbum) {
        final cleanAlbum = AudiobookGroupingUtils.cleanBookTitle(album);
        groupKey = 'album:${cleanAlbum.toLowerCase()}:::${artist.toLowerCase()}';
        groupFolderMap[groupKey] = resolvedBookDir.path;
      } else {
        groupKey = 'dir:${resolvedBookDir.path}';
        groupFolderMap[groupKey] = resolvedBookDir.path;
      }

      filesByGroupKey.putIfAbsent(groupKey, () => []).add(file);
    }

    final discoveredBooks = <DiscoveredBook>[];

    for (final entry in filesByGroupKey.entries) {
      final groupKey = entry.key;
      final files = entry.value;
      final bookFolderPath = groupFolderMap[groupKey] ?? files.first.parent.path;

      final bookId = _uuid.v4();
      final tracks = <AudioTrack>[];
      int totalDurationMs = 0;
      String? detectedAlbum;
      String? detectedArtist;
      String? detectedAlbumArtist;
      String? detectedNarrator;
      String? embeddedCoverPath;

      // Check local folder for cover image (book folder first, then subfolders)
      String? coverPath = await _artworkService.findLocalCover(bookFolderPath);
      if (coverPath == null) {
        for (final file in files) {
          if (file.parent.path != bookFolderPath) {
            coverPath = await _artworkService.findLocalCover(file.parent.path);
            if (coverPath != null) break;
          }
        }
      }

      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final meta = metadataMap[file.path] ?? const AudioMetadataResult();
        final fileName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'Track ${i + 1}';
        final trackTitle = meta.title ?? AudiobookGroupingUtils.cleanTrackTitle(fileName);
        final trackDuration = (meta.durationMs != null && meta.durationMs! > 0)
            ? meta.durationMs!
            : 0;
        totalDurationMs += trackDuration;

        if (detectedAlbum == null && meta.album != null && meta.album!.trim().isNotEmpty) {
          detectedAlbum = meta.album!.trim();
        }
        if (detectedArtist == null && meta.artist != null && meta.artist!.trim().isNotEmpty) {
          detectedArtist = meta.artist!.trim();
        }
        if (detectedAlbumArtist == null && meta.albumArtist != null && meta.albumArtist!.trim().isNotEmpty) {
          detectedAlbumArtist = meta.albumArtist!.trim();
        }
        if (detectedNarrator == null && meta.narrator != null && meta.narrator!.trim().isNotEmpty) {
          detectedNarrator = meta.narrator!.trim();
        }

        // If no local cover yet, extract embedded picture safely
        if (coverPath == null &&
            embeddedCoverPath == null &&
            meta.pictureBytes != null &&
            meta.pictureBytes!.isNotEmpty) {
          try {
            final isPng = meta.mimeType != null && meta.mimeType!.toLowerCase().contains('png');
            embeddedCoverPath = await _artworkService.saveEmbeddedArtwork(
              meta.pictureBytes!,
              extension: isPng ? 'png' : 'jpg',
            );
          } catch (_) {
            embeddedCoverPath = null;
          }
        }

        final ext = AudioFormatUtils.getExtension(file.path).toUpperCase();
        final discNum = (meta.discNumber != null && meta.discNumber! > 0)
            ? meta.discNumber!
            : AudiobookGroupingUtils.extractDiscNumber(file.path);

        final trackNum = (meta.trackNumber != null && meta.trackNumber! > 0)
            ? meta.trackNumber!
            : (AudiobookGroupingUtils.extractTrackNumber(fileName) ?? (i + 1));

        int fileSizeBytes = 0;
        try {
          if (await file.exists()) {
            fileSizeBytes = await file.length();
          }
        } catch (_) {}

        tracks.add(AudioTrack(
          id: _uuid.v4(),
          audiobookId: bookId,
          filePath: file.path,
          fileName: fileName,
          chapterTitle: trackTitle,
          trackOrder: trackNum,
          discNumber: discNum,
          durationMs: trackDuration,
          format: ext.isEmpty ? 'AUDIO' : ext,
          fileSizeBytes: fileSizeBytes,
          author: meta.artist ?? detectedArtist,
        ));
      }

      // Sort tracks using multi-tier compareTracks (disc -> trackNumber -> natural filename -> natural path)
      tracks.sort((a, b) {
        final metaA = metadataMap[a.filePath];
        final metaB = metadataMap[b.filePath];
        return AudiobookGroupingUtils.compareTracks(
          pathA: a.filePath,
          nameA: a.fileName,
          discA: a.discNumber,
          trackA: metaA?.trackNumber,
          pathB: b.filePath,
          nameB: b.fileName,
          discB: b.discNumber,
          trackB: metaB?.trackNumber,
        );
      });

      // Normalize trackOrder 1..N
      for (var i = 0; i < tracks.length; i++) {
        tracks[i] = tracks[i].copyWith(trackOrder: i + 1);
      }

      // Determine book title:
      final rawFolderName = Directory(bookFolderPath).uri.pathSegments
          .where((s) => s.isNotEmpty)
          .lastOrNull ?? 'Audiobook';
      final cleanFolderName = AudiobookGroupingUtils.cleanBookTitle(rawFolderName);
      final cleanAlbum = detectedAlbum != null
          ? AudiobookGroupingUtils.cleanBookTitle(detectedAlbum)
          : null;

      final bookTitle = cleanAlbum ??
          (cleanFolderName.toLowerCase() == 'audiobooks'
              ? (tracks.isNotEmpty ? tracks.first.title : cleanFolderName)
              : cleanFolderName);
      final authorNarrator = AudiobookGroupingUtils.resolveAuthorAndNarrator(
        artist: detectedArtist,
        albumArtist: detectedAlbumArtist,
        explicitNarrator: detectedNarrator,
        title: bookTitle,
        path: bookFolderPath,
      );

      discoveredBooks.add(DiscoveredBook(
        id: bookId,
        title: bookTitle,
        author: authorNarrator.author,
        narrator: authorNarrator.narrator,
        coverPath: coverPath ?? embeddedCoverPath,
        folderPath: bookFolderPath,
        tracks: tracks,
        totalDurationMs: totalDurationMs,
      ));
    }

    return AudiobookScanResult(books: discoveredBooks, rejectedFiles: rejectedFiles);
  }

  /// Groups loose picked files into one or multiple DiscoveredBooks
  Future<AudiobookScanResult> processPickedFiles(List<File> files) async {
    if (files.isEmpty) return AudiobookScanResult();

    final validAudioFiles = <File>[];
    final rejectedFiles = <RejectedAudioFile>[];

    // Copy before sorting to prevent mutating caller's list or failing on unmodifiable lists
    final filesCopy = List<File>.from(files);
    filesCopy.sort((a, b) => AudiobookGroupingUtils.naturalCompare(a.path, b.path));

    for (final file in filesCopy) {
      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : file.path.split(Platform.pathSeparator).last;

      if (!AudioFormatUtils.isSupported(file.path)) {
        rejectedFiles.add(RejectedAudioFile(
          fileName: fileName,
          filePath: file.path,
          reason: RejectedFileReason.unsupportedFormat,
        ));
        continue;
      }

      try {
        if (await file.exists()) {
          final length = await file.length();
          if (length == 0) {
            rejectedFiles.add(RejectedAudioFile(
              fileName: fileName,
              filePath: file.path,
              reason: RejectedFileReason.emptyFile,
            ));
            continue;
          }
        }
      } catch (e) {
        rejectedFiles.add(RejectedAudioFile(
          fileName: fileName,
          filePath: file.path,
          reason: RejectedFileReason.inaccessible,
          details: e.toString(),
        ));
        continue;
      }

      validAudioFiles.add(file);
    }

    if (validAudioFiles.isEmpty) {
      return AudiobookScanResult(books: [], rejectedFiles: rejectedFiles);
    }

    final metadataMap = <String, AudioMetadataResult>{};
    final processableFiles = <File>[];

    for (final file in validAudioFiles) {
      final fileName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : file.path.split(Platform.pathSeparator).last;

      try {
        final meta = await _metadataService.readMetadata(file.path);
        bool exists = false;
        try {
          exists = await file.exists();
        } catch (_) {}

        // If file does not exist on disk and no mock/actual metadata was returned, mark inaccessible
        if (!exists && meta == const AudioMetadataResult()) {
          rejectedFiles.add(RejectedAudioFile(
            fileName: fileName,
            filePath: file.path,
            reason: RejectedFileReason.inaccessible,
          ));
          continue;
        }

        metadataMap[file.path] = meta;
        processableFiles.add(file);
      } catch (e) {
        final isNotFound = e.toString().contains('NotFound') ||
            e.toString().contains('No such file') ||
            e.toString().contains('PathNotFound');
        rejectedFiles.add(RejectedAudioFile(
          fileName: fileName,
          filePath: file.path,
          reason: isNotFound ? RejectedFileReason.inaccessible : RejectedFileReason.unreadable,
          details: e.toString(),
        ));
      }
    }

    if (processableFiles.isEmpty) {
      return AudiobookScanResult(books: [], rejectedFiles: rejectedFiles);
    }

    // Group by compound key: album + artist, or resolved book folder path
    final grouped = <String, List<File>>{};

    for (final file in processableFiles) {
      final meta = metadataMap[file.path] ?? const AudioMetadataResult();
      final album = meta.album?.trim();
      final artist = meta.albumArtist?.trim() ?? meta.artist?.trim() ?? '';

      final isGenericAlbum = album == null ||
          album.isEmpty ||
          RegExp(r'^(?:audiobook|audio|unknown|music|disc|cd|track)$', caseSensitive: false)
              .hasMatch(album);

      final String groupKey;
      if (!isGenericAlbum) {
        final cleanAlbum = AudiobookGroupingUtils.cleanBookTitle(album);
        groupKey = 'album:${cleanAlbum.toLowerCase()}:::${artist.toLowerCase()}';
      } else {
        final resolvedDir = AudiobookGroupingUtils.resolveBookDirectory(file.parent);
        groupKey = 'dir:${resolvedDir.path}';
      }

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
      String? detectedAlbumArtist;
      String? detectedNarrator;
      String? embeddedCoverPath;

      // Check local folder for cover image first before extracting embedded artwork
      final bookFolder = AudiobookGroupingUtils.resolveBookDirectory(bookFiles.first.parent);
      String? localCoverPath = await _artworkService.findLocalCover(bookFolder.path);
      if (localCoverPath == null) {
        for (final file in bookFiles) {
          if (file.parent.path != bookFolder.path) {
            localCoverPath = await _artworkService.findLocalCover(file.parent.path);
            if (localCoverPath != null) break;
          }
        }
      }

      for (var i = 0; i < bookFiles.length; i++) {
        final file = bookFiles[i];
        final meta = metadataMap[file.path] ?? const AudioMetadataResult();
        final fileName = file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'Track ${i + 1}';
        final trackTitle = meta.title ?? AudiobookGroupingUtils.cleanTrackTitle(fileName);
        final trackDuration = (meta.durationMs != null && meta.durationMs! > 0)
            ? meta.durationMs!
            : 0;
        totalDurationMs += trackDuration;

        if (detectedAlbum == null && meta.album != null && meta.album!.trim().isNotEmpty) {
          detectedAlbum = meta.album!.trim();
        }
        if (detectedArtist == null && meta.artist != null && meta.artist!.trim().isNotEmpty) {
          detectedArtist = meta.artist!.trim();
        }
        if (detectedAlbumArtist == null && meta.albumArtist != null && meta.albumArtist!.trim().isNotEmpty) {
          detectedAlbumArtist = meta.albumArtist!.trim();
        }
        if (detectedNarrator == null && meta.narrator != null && meta.narrator!.trim().isNotEmpty) {
          detectedNarrator = meta.narrator!.trim();
        }

        if (localCoverPath == null &&
            embeddedCoverPath == null &&
            meta.pictureBytes != null &&
            meta.pictureBytes!.isNotEmpty) {
          try {
            final isPng = meta.mimeType != null && meta.mimeType!.toLowerCase().contains('png');
            embeddedCoverPath = await _artworkService.saveEmbeddedArtwork(
              meta.pictureBytes!,
              extension: isPng ? 'png' : 'jpg',
            );
          } catch (_) {
            embeddedCoverPath = null;
          }
        }

        final ext = AudioFormatUtils.getExtension(file.path).toUpperCase();
        final discNum = (meta.discNumber != null && meta.discNumber! > 0)
            ? meta.discNumber!
            : AudiobookGroupingUtils.extractDiscNumber(file.path);

        final trackNum = (meta.trackNumber != null && meta.trackNumber! > 0)
            ? meta.trackNumber!
            : (AudiobookGroupingUtils.extractTrackNumber(fileName) ?? (i + 1));

        int fileSizeBytes = 0;
        try {
          if (await file.exists()) {
            fileSizeBytes = await file.length();
          }
        } catch (_) {}

        tracks.add(AudioTrack(
          id: _uuid.v4(),
          audiobookId: bookId,
          filePath: file.path,
          fileName: fileName,
          chapterTitle: trackTitle,
          trackOrder: trackNum,
          discNumber: discNum,
          durationMs: trackDuration,
          format: ext.isEmpty ? 'AUDIO' : ext,
          fileSizeBytes: fileSizeBytes,
          author: meta.artist ?? meta.albumArtist ?? detectedArtist,
        ));
      }

      // Sort tracks using multi-tier compareTracks
      tracks.sort((a, b) {
        final metaA = metadataMap[a.filePath];
        final metaB = metadataMap[b.filePath];
        return AudiobookGroupingUtils.compareTracks(
          pathA: a.filePath,
          nameA: a.fileName,
          discA: a.discNumber,
          trackA: metaA?.trackNumber,
          pathB: b.filePath,
          nameB: b.fileName,
          discB: b.discNumber,
          trackB: metaB?.trackNumber,
        );
      });

      for (var i = 0; i < tracks.length; i++) {
        tracks[i] = tracks[i].copyWith(trackOrder: i + 1);
      }

      final rawFolderName = bookFolder.uri.pathSegments
          .where((s) => s.isNotEmpty)
          .lastOrNull ?? 'Imported Audiobook';
      final cleanFolderName = AudiobookGroupingUtils.cleanBookTitle(rawFolderName);
      final cleanAlbum = detectedAlbum != null
          ? AudiobookGroupingUtils.cleanBookTitle(detectedAlbum)
          : null;

      final bookTitle = cleanAlbum ??
          (tracks.length == 1
              ? tracks.first.title
              : (cleanFolderName.toLowerCase() == 'audiobooks' ? 'Imported Audiobook' : cleanFolderName));

      final authorNarrator = AudiobookGroupingUtils.resolveAuthorAndNarrator(
        artist: detectedArtist,
        albumArtist: detectedAlbumArtist,
        explicitNarrator: detectedNarrator,
        title: bookTitle,
        path: bookFolder.path,
      );

      results.add(DiscoveredBook(
        id: bookId,
        title: bookTitle,
        author: authorNarrator.author,
        narrator: authorNarrator.narrator,
        coverPath: localCoverPath ?? embeddedCoverPath,
        folderPath: bookFolder.path,
        tracks: tracks,
        totalDurationMs: totalDurationMs,
      ));
    }

    return AudiobookScanResult(books: results, rejectedFiles: rejectedFiles);
  }
}

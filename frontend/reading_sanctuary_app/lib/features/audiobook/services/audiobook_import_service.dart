import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../data/datasources/audiobook_local_datasource.dart';
import '../data/models/audiobook.dart';
import '../data/models/playback_progress.dart';
import '../utils/audio_format_utils.dart';
import 'audiobook_scanner_service.dart';
import 'audiobook_duplicate_detection_service.dart';

class AudiobookImportResult {
  final List<Audiobook> importedBooks;
  final List<Audiobook> skippedBooks;
  final List<Audiobook> replacedBooks;
  final List<String> errors;

  const AudiobookImportResult({
    this.importedBooks = const [],
    this.skippedBooks = const [],
    this.replacedBooks = const [],
    this.errors = const [],
  });

  int get successfulCount => importedBooks.length + replacedBooks.length;

  bool get hasErrors => errors.isNotEmpty;
}

class AudioFilePickResult {
  final List<File> validFiles;
  final List<String> unsupportedFiles;
  final List<String> inaccessibleFiles;
  final bool wasCancelled;

  const AudioFilePickResult({
    this.validFiles = const [],
    this.unsupportedFiles = const [],
    this.inaccessibleFiles = const [],
    this.wasCancelled = false,
  });

  bool get hasIssues => unsupportedFiles.isNotEmpty || inaccessibleFiles.isNotEmpty;
  bool get isEmpty => validFiles.isEmpty;
}

class AudiobookImportService {
  final AudiobookScannerService _scannerService;
  final AudiobookLocalDatasource _localDatasource;

  AudiobookImportService({
    AudiobookScannerService? scannerService,
    AudiobookLocalDatasource? localDatasource,
  })  : _scannerService = scannerService ?? AudiobookScannerService(),
        _localDatasource = localDatasource ?? AudiobookLocalDatasource();

  /// Pick multiple audio files with detailed validation reporting
  Future<AudioFilePickResult> pickAudioFilesDetailed() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AudioFormatUtils.supportedExtensions.toList(),
      allowMultiple: true,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return const AudioFilePickResult(wasCancelled: true);
    }

    final valid = <File>[];
    final unsupported = <String>[];
    final inaccessible = <String>[];

    for (final pf in result.files) {
      final path = pf.path;
      if (path == null) {
        inaccessible.add(pf.name);
        continue;
      }

      final file = File(path);
      if (!file.existsSync()) {
        inaccessible.add(pf.name);
        continue;
      }

      if (!AudioFormatUtils.isSupported(path)) {
        unsupported.add(pf.name);
        continue;
      }

      valid.add(file);
    }

    return AudioFilePickResult(
      validFiles: valid,
      unsupportedFiles: unsupported,
      inaccessibleFiles: inaccessible,
      wasCancelled: false,
    );
  }

  /// Backwards-compatible file picker returning only valid files
  Future<List<File>> pickAudioFiles() async {
    final detailed = await pickAudioFilesDetailed();
    return detailed.validFiles;
  }

  /// Pick an audiobook folder with validation that the directory exists
  Future<String?> pickAudiobookFolder() async {
    final folderPath = await FilePicker.platform.getDirectoryPath();
    if (folderPath == null || folderPath.trim().isEmpty) {
      return null;
    }

    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      return null;
    }

    return folderPath;
  }

  /// Scan a folder and return proposed books and rejected files before importing
  Future<AudiobookScanResult> previewFolderScan(String folderPath) async {
    return _scannerService.scanFolder(folderPath);
  }

  /// Process picked files into proposed books and rejected files before importing
  Future<AudiobookScanResult> previewPickedFiles(List<File> files) async {
    return _scannerService.processPickedFiles(files);
  }

  /// Commit discovered books with duplicate decisions to the local database
  Future<AudiobookImportResult> commitImportedBooks({
    required List<AudiobookDuplicateEntry> entries,
  }) async {
    final imported = <Audiobook>[];
    final skipped = <Audiobook>[];
    final replaced = <Audiobook>[];
    final errors = <String>[];

    // Reject unresolved duplicate decisions rather than silently choosing
    for (final entry in entries) {
      if (entry.result.isDuplicate && entry.action == null) {
        errors.add('Missing duplicate decision for "${entry.book.title}". Please choose to Skip, Import Anyway, or Replace.');
      }
    }

    if (errors.isNotEmpty) {
      return AudiobookImportResult(
        importedBooks: imported,
        skippedBooks: skipped,
        replacedBooks: replaced,
        errors: errors,
      );
    }

    const uuid = Uuid();

    for (final entry in entries) {
      final disc = entry.book;
      final action = entry.action;

      if (entry.result.isDuplicate && action == DuplicateAction.skip) {
        skipped.add(disc.toAudiobook());
        continue;
      }

      if (entry.result.isDuplicate && action == DuplicateAction.replace) {
        final existingId = entry.result.existingBookId;
        if (existingId == null) {
          errors.add('Cannot replace "${disc.title}": no unambiguous existing audiobook match.');
          continue;
        }

        try {
          final bookToSave = disc.toAudiobook().copyWith(id: existingId);
          final tracksToSave = disc.tracks.map((t) => t.copyWith(audiobookId: existingId)).toList();

          await _localDatasource.replaceAudiobook(
            book: bookToSave,
            tracks: tracksToSave,
            resetProgress: true,
          );
          replaced.add(bookToSave);
        } catch (e) {
          errors.add('Failed to replace "${disc.title}": $e');
        }
        continue;
      }

      // Import Anyway or Non-duplicate: generate new audiobook ID and track IDs
      try {
        final newBookId = uuid.v4();
        final bookToSave = disc.toAudiobook().copyWith(id: newBookId);
        final tracksToSave = disc.tracks.map((t) => t.copyWith(
          id: uuid.v4(),
          audiobookId: newBookId,
        )).toList();

        await _localDatasource.saveAudiobook(bookToSave, tracksToSave);

        final initialProgress = PlaybackProgress(
          audiobookId: newBookId,
          currentTrackId: tracksToSave.isNotEmpty ? tracksToSave.first.id : null,
          trackIndex: 0,
          positionMs: 0,
          totalDurationMs: disc.totalDurationMs,
          playbackSpeed: 1.0,
          lastListenedAt: DateTime.now(),
          completed: false,
        );
        await _localDatasource.saveProgressRecord(initialProgress);
        imported.add(bookToSave);
      } catch (e) {
        errors.add('Failed to save "${disc.title}": $e');
      }
    }

    return AudiobookImportResult(
      importedBooks: imported,
      skippedBooks: skipped,
      replacedBooks: replaced,
      errors: errors,
    );
  }
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../data/datasources/audiobook_local_datasource.dart';
import '../data/models/audiobook.dart';
import '../data/models/audio_track.dart';
import '../data/models/playback_progress.dart';
import '../utils/audio_format_utils.dart';
import 'audiobook_scanner_service.dart';

class AudiobookImportService {
  final AudiobookScannerService _scannerService;
  final AudiobookLocalDatasource _localDatasource;

  AudiobookImportService({
    AudiobookScannerService? scannerService,
    AudiobookLocalDatasource? localDatasource,
  })  : _scannerService = scannerService ?? AudiobookScannerService(),
        _localDatasource = localDatasource ?? AudiobookLocalDatasource();

  /// Pick multiple audio files using the file picker
  Future<List<File>> pickAudioFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AudioFormatUtils.supportedExtensions.toList(),
      allowMultiple: true,
      withData: false,
    );

    if (result == null) return [];

    return result.files
        .where((file) => file.path != null && AudioFormatUtils.isSupported(file.path!))
        .map((file) => File(file.path!))
        .toList();
  }

  /// Pick an audiobook folder
  Future<String?> pickAudiobookFolder() async {
    return FilePicker.platform.getDirectoryPath();
  }

  /// Scan a folder and return proposed books before importing
  Future<List<DiscoveredBook>> previewFolderScan(String folderPath) async {
    return _scannerService.scanFolder(folderPath);
  }

  /// Process picked files into proposed books before importing
  Future<List<DiscoveredBook>> previewPickedFiles(List<File> files) async {
    return _scannerService.processPickedFiles(files);
  }

  /// Commit discovered books to the local database
  Future<List<Audiobook>> commitImportedBooks(List<DiscoveredBook> discovered) async {
    final imported = <Audiobook>[];
    for (final disc in discovered) {
      final book = disc.toAudiobook();
      await _localDatasource.saveAudiobook(book, disc.tracks);

      // Create initial playback progress
      final initialProgress = PlaybackProgress(
        audiobookId: book.id,
        currentTrackId: disc.tracks.isNotEmpty ? disc.tracks.first.id : null,
        trackIndex: 0,
        positionMs: 0,
        totalDurationMs: disc.totalDurationMs,
        playbackSpeed: 1.0,
        lastListenedAt: DateTime.now(),
        completed: false,
      );
      await _localDatasource.saveProgressRecord(initialProgress);
      imported.add(book);
    }
    return imported;
  }
}

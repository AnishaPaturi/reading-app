import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/audiobook_local_datasource.dart';
import '../../data/models/audiobook_bookmark.dart';
import '../../data/models/listening_event.dart';
import '../../services/audiobook_metadata_service.dart';
import '../../services/audiobook_artwork_service.dart';
import '../../services/audiobook_scanner_service.dart';
import '../../services/audiobook_import_service.dart';
import '../../services/audiobook_chapter_service.dart';
import '../../services/audiobook_sleep_timer_service.dart';
import '../../services/audiobook_history_service.dart';
import '../../services/audiobook_playback_service.dart';
import '../../services/audiobook_bookmark_service.dart';
import '../../services/audiobook_duplicate_detection_service.dart';

final audiobookLocalDatasourceProvider = Provider<AudiobookLocalDatasource>((ref) {
  final ds = AudiobookLocalDatasource();
  return ds;
});

final audiobookDuplicateDetectionServiceProvider = Provider<AudiobookDuplicateDetectionService>((ref) {
  return AudiobookDuplicateDetectionService(
    dataSource: ref.watch(audiobookLocalDatasourceProvider),
  );
});

final audiobookMetadataServiceProvider = Provider<AudiobookMetadataService>((ref) {
  return AudiobookMetadataService();
});

final audiobookArtworkServiceProvider = Provider<AudiobookArtworkService>((ref) {
  return AudiobookArtworkService();
});

final audiobookScannerServiceProvider = Provider<AudiobookScannerService>((ref) {
  return AudiobookScannerService(
    metadataService: ref.watch(audiobookMetadataServiceProvider),
    artworkService: ref.watch(audiobookArtworkServiceProvider),
  );
});

final audiobookImportServiceProvider = Provider<AudiobookImportService>((ref) {
  return AudiobookImportService(
    scannerService: ref.watch(audiobookScannerServiceProvider),
    localDatasource: ref.watch(audiobookLocalDatasourceProvider),
  );
});

final audiobookChapterServiceProvider = Provider<AudiobookChapterService>((ref) {
  return AudiobookChapterService(
    localDatasource: ref.watch(audiobookLocalDatasourceProvider),
  );
});

final audiobookSleepTimerServiceProvider = Provider<AudiobookSleepTimerService>((ref) {
  final service = AudiobookSleepTimerService();
  ref.onDispose(service.dispose);
  return service;
});

final audiobookHistoryServiceProvider = Provider<AudiobookHistoryService>((ref) {
  return AudiobookHistoryService(
    localDatasource: ref.watch(audiobookLocalDatasourceProvider),
  );
});

final audiobookBookmarkServiceProvider = Provider<AudiobookBookmarkService>((ref) {
  return AudiobookBookmarkService(
    localDatasource: ref.watch(audiobookLocalDatasourceProvider),
  );
});

final audiobookPlaybackServiceProvider = Provider<AudiobookPlaybackService>((ref) {
  final service = AudiobookPlaybackService(
    localDatasource: ref.watch(audiobookLocalDatasourceProvider),
    chapterService: ref.watch(audiobookChapterServiceProvider),
    sleepTimerService: ref.watch(audiobookSleepTimerServiceProvider),
    historyService: ref.watch(audiobookHistoryServiceProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

final audiobookNightAppearanceProvider = StreamProvider<bool>((ref) {
  final timer = ref.watch(audiobookSleepTimerServiceProvider);
  return timer.nightModeStream;
});

final audiobookPaletteProvider =
    FutureProvider.family<ArtworkPalette, String?>((ref, coverPath) async {
  final artworkService = ref.watch(audiobookArtworkServiceProvider);
  return artworkService.extractPalette(coverPath);
});

final audiobookResumeSuggestionProvider = Provider<ResumeSuggestion?>((ref) {
  final historyService = ref.watch(audiobookHistoryServiceProvider);
  return historyService.getLatestResumeSuggestion();
});

final audiobookBookmarksListProvider =
    FutureProvider.family<List<AudiobookBookmark>, String>((ref, bookId) async {
  final service = ref.watch(audiobookBookmarkServiceProvider);
  return service.getBookmarksForBook(bookId);
});

final audiobookAllBookmarksProvider = Provider<List<AudiobookBookmark>>((ref) {
  final service = ref.watch(audiobookBookmarkServiceProvider);
  return service.getAllBookmarks();
});

final audiobookHistoryListProvider = Provider<List<ListeningSession>>((ref) {
  final service = ref.watch(audiobookHistoryServiceProvider);
  return service.getAllHistory();
});

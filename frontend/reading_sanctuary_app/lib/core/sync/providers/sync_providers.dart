import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_models.dart';
import '../services/local_storage_db.dart';
import '../services/sync_api_service.dart';
import '../services/sync_engine.dart';
import '../../../features/cloud_storage/data/services/cloud_storage_api_service.dart';
import '../../../features/offline/domain/models/download_task.dart';
import '../../../features/offline/services/download_manager.dart';
import '../../../features/offline/services/downloads_scanner_service.dart';
import '../../../features/offline/services/offline_tts_cache_service.dart';
import '../../../features/reader/presentation/providers/reader_provider.dart';

final localStorageDbProvider = Provider<LocalStorageDb>((ref) {
  final db = LocalStorageDb();
  db.init();
  return db;
});

final cloudStorageApiServiceProvider = Provider<CloudStorageApiService>((ref) {
  final token = ref.watch(authTokenProvider);
  return CloudStorageApiService(
    tokenProvider: () => token,
  );
});

final downloadManagerProvider = ChangeNotifierProvider<DownloadManager>((ref) {
  final db = ref.watch(localStorageDbProvider);
  final api = ref.watch(cloudStorageApiServiceProvider);
  final manager = DownloadManager(localDb: db, storageApi: api);
  manager.init();
  return manager;
});

final offlineTtsCacheServiceProvider = Provider<OfflineTtsCacheService>((ref) {
  return OfflineTtsCacheService();
});

final syncApiServiceProvider = Provider<SyncApiService>((ref) {
  final token = ref.watch(authTokenProvider);
  return SyncApiService(
    tokenProvider: () => token,
  );
});

final syncEngineProvider = ChangeNotifierProvider<SyncEngine>((ref) {
  final db = ref.watch(localStorageDbProvider);
  final api = ref.watch(syncApiServiceProvider);
  final engine = SyncEngine(localDb: db, syncApi: api);
  engine.init();
  engine.startAutoSync();
  return engine;
});

final syncStatusProvider = Provider<SyncStatus>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.status;
});

final pendingSyncCountProvider = Provider<int>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.pendingCount;
});

final syncConflictsProvider = Provider<List<SyncConflictItem>>((ref) {
  final engine = ref.watch(syncEngineProvider);
  return engine.activeConflicts;
});

final fileDownloadTaskProvider = Provider.family<DownloadTask?, String>((ref, fileId) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.getTask(fileId);
});

final isFileDownloadedProvider = Provider.family<bool, String>((ref, fileId) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.isDownloaded(fileId);
});

final downloadsScannerServiceProvider =
    ChangeNotifierProvider<DownloadsScannerService>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return DownloadsScannerService(downloadManager: manager);
});

final downloadsSortOptionProvider =
    StateProvider<DownloadsSortOption>((ref) => DownloadsSortOption.newestFirst);

final activeDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.getActiveDownloads();
});

final recentlyDownloadedProvider = Provider<List<DownloadTask>>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  final sort = ref.watch(downloadsSortOptionProvider);
  return manager.getRecentlyDownloadedBooks(sort: sort);
});

final allDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  final sort = ref.watch(downloadsSortOptionProvider);
  return manager.getCompletedDownloads(sort: sort);
});

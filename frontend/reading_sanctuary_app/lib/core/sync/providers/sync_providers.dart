import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sync_models.dart';
import '../services/local_storage_db.dart';
import '../services/sync_api_service.dart';
import '../services/sync_engine.dart';
import '../../../features/cloud_storage/data/services/cloud_storage_api_service.dart';
import '../../../features/offline/domain/models/download_task.dart';
import '../../../features/offline/services/download_manager.dart';
import '../../../features/offline/services/offline_tts_cache_service.dart';
import '../../../features/reader/presentation/providers/reader_provider.dart';

final localStorageDbProvider = Provider<LocalStorageDb>((ref) {
  final db = LocalStorageDb();
  db.init();
  return db;
});

final cloudStorageApiServiceProvider = Provider<CloudStorageApiService>((ref) {
  return CloudStorageApiService(
    tokenProvider: () => ref.watch(authTokenProvider),
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
  return SyncApiService(
    tokenProvider: () => ref.watch(authTokenProvider),
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

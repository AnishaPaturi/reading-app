import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../domain/models/download_task.dart';
import '../../../core/sync/services/local_storage_db.dart';
import '../../cloud_storage/data/services/cloud_storage_api_service.dart';

class DownloadManager extends ChangeNotifier {
  final LocalStorageDb localDb;
  final CloudStorageApiService? storageApi;
  final http.Client _httpClient;
  final String? customDownloadDirPath;

  final Map<String, DownloadTask> _tasks = {};
  final Map<String, bool> _cancelledMap = {};
  final Map<String, bool> _pausedMap = {};
  bool _initialized = false;

  DownloadManager({
    required this.localDb,
    this.storageApi,
    http.Client? httpClient,
    this.customDownloadDirPath,
  }) : _httpClient = httpClient ?? http.Client();

  Future<void> init() async {
    if (_initialized) return;
    await localDb.init();

    final saved = localDb.getAllDownloads();
    _tasks.addAll(saved);

    // Verify physical file existence on disk for completed downloads
    if (!kIsWeb) {
      for (final entry in _tasks.entries.toList()) {
        if (entry.value.isCompleted) {
          final f = File(entry.value.localPath);
          if (!await f.exists()) {
            _tasks.remove(entry.key);
            await localDb.removeDownload(entry.key);
          }
        }
      }
    }

    _initialized = true;
    notifyListeners();
  }

  DownloadTask? getTask(String fileId) => _tasks[fileId];

  bool isDownloaded(String fileId) {
    if (kIsWeb) return false;
    final task = _tasks[fileId];
    if (task == null || task.status != DownloadStatus.downloaded) return false;
    return File(task.localPath).existsSync();
  }

  String? getLocalFilePath(String fileId) {
    if (kIsWeb) return null;
    // 1. Direct match on fileId
    final task = _tasks[fileId];
    if (task != null && task.status == DownloadStatus.downloaded) {
      final f = File(task.localPath);
      if (f.existsSync()) return task.localPath;
    }

    // 2. Lookup by bookId
    for (final t in _tasks.values) {
      if (t.bookId == fileId && t.status == DownloadStatus.downloaded) {
        final f = File(t.localPath);
        if (f.existsSync()) return t.localPath;
      }
    }

    // 3. Direct local file path
    final directFile = File(fileId);
    if (directFile.existsSync()) return directFile.path;

    return null;
  }

  Future<Uint8List?> getLocalFileBytes(String fileId) async {
    if (kIsWeb) return null;
    final path = getLocalFilePath(fileId);
    if (path == null) return null;
    final f = File(path);
    if (await f.exists()) {
      return await f.readAsBytes();
    }
    return null;
  }

  /// Returns all active downloads (queued, downloading, or paused).
  List<DownloadTask> getActiveDownloads() {
    return _tasks.values.where((t) => t.isActive).toList();
  }

  /// Returns all completed downloads, optionally sorted by date.
  List<DownloadTask> getCompletedDownloads({
    DownloadsSortOption sort = DownloadsSortOption.newestFirst,
  }) {
    final list = _tasks.values
        .where((t) => t.isCompleted && File(t.localPath).existsSync())
        .toList();
    list.sort((a, b) => DownloadTask.compareByDate(
          a,
          b,
          newestFirst: sort == DownloadsSortOption.newestFirst,
        ));
    return list;
  }

  /// Backward-compatible alias for existing callers.
  List<DownloadTask> getAllDownloads() {
    return getCompletedDownloads();
  }

  /// Returns only recently downloaded books:
  /// - Downloaded via application (`!isDiscovered` && `source == appDownload`)
  /// - Have a verified `downloadedAt` timestamp
  /// - Sorted newest first by default
  /// - Discovered files from Downloads folder are strictly excluded!
  List<DownloadTask> getRecentlyDownloadedBooks({
    int limit = 20,
    DownloadsSortOption sort = DownloadsSortOption.newestFirst,
  }) {
    final list = _tasks.values
        .where((t) => t.isRecentlyDownloaded && File(t.localPath).existsSync())
        .toList();
    list.sort((a, b) => DownloadTask.compareByDate(
          a,
          b,
          newestFirst: sort == DownloadsSortOption.newestFirst,
        ));
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  /// Returns books discovered in device Downloads folder.
  List<DownloadTask> getDiscoveredDownloads({
    DownloadsSortOption sort = DownloadsSortOption.newestFirst,
  }) {
    final list = _tasks.values
        .where((t) => t.isCompleted && t.isDiscovered && File(t.localPath).existsSync())
        .toList();
    list.sort((a, b) => DownloadTask.compareByDate(
          a,
          b,
          newestFirst: sort == DownloadsSortOption.newestFirst,
        ));
    return list;
  }

  /// Filtered and sorted downloads for the complete Downloads listing.
  List<DownloadTask> getAllDownloadsFiltered({
    DownloadsSortOption sort = DownloadsSortOption.newestFirst,
    String? searchQuery,
    String? formatFilter,
  }) {
    var list = getCompletedDownloads(sort: sort);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      list = list.where((t) {
        final title = t.bookTitle.toLowerCase();
        final author = (t.author ?? '').toLowerCase();
        final fileName = t.fileName.toLowerCase();
        return title.contains(query) ||
            author.contains(query) ||
            fileName.contains(query);
      }).toList();
    }

    if (formatFilter != null &&
        formatFilter.isNotEmpty &&
        formatFilter.toLowerCase() != 'all') {
      final target = formatFilter.toLowerCase();
      list = list.where((t) => t.format.toLowerCase() == target).toList();
    }

    return list;
  }

  int calculateTotalStorageBytes() {
    int total = 0;
    for (final t in _tasks.values) {
      if (t.isCompleted) {
        total += t.totalBytes > 0 ? t.totalBytes : t.downloadedBytes;
      }
    }
    return total;
  }

  Future<String> _resolveDirectory(String fileId) async {
    if (customDownloadDirPath != null) {
      final dir = Directory('$customDownloadDirPath/$fileId');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir.path;
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/sanctuary_offline/$fileId');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  /// Downloads a book file with real-time streaming progress and checksum verification.
  Future<void> downloadBookFile({
    required String bookId,
    required String fileId,
    required String bookTitle,
    required String fileName,
    required String format,
    String? author,
    String? coverUrl,
    String? directDownloadUrl,
    String? expectedChecksum,
  }) async {
    _cancelledMap[fileId] = false;
    _pausedMap[fileId] = false;

    final targetDir = await _resolveDirectory(fileId);
    final targetPath = '$targetDir/$fileName';

    var current = DownloadTask(
      fileId: fileId,
      bookId: bookId,
      bookTitle: bookTitle,
      author: author,
      coverUrl: coverUrl,
      fileName: fileName,
      format: format,
      localPath: targetPath,
      status: DownloadStatus.downloading,
      source: DownloadSource.appDownload,
      isDiscovered: false,
      checksum: expectedChecksum,
    );

    _tasks[fileId] = current;
    notifyListeners();

    IOSink? sink;
    try {
      String downloadUrl = directDownloadUrl ?? '';
      String? checksumToVerify = expectedChecksum;

      if (downloadUrl.isEmpty && storageApi != null) {
        final result = await storageApi!.getDownloadUrl(fileId);
        downloadUrl = result.downloadUrl;
        checksumToVerify ??= result.checksum;
      }

      if (downloadUrl.isEmpty) {
        final base = storageApi?.baseUrl ?? 'http://localhost:8080/api/v1';
        downloadUrl = '$base/books/$bookId/files/$fileId';
      }

      final uri = Uri.parse(downloadUrl);
      final token = storageApi?.tokenProvider();
      final headers = <String, String>{
        if (token != null && !downloadUrl.contains('X-Amz-Signature'))
          'Authorization': 'Bearer $token',
      };

      final request = http.Request('GET', uri);
      request.headers.addAll(headers);

      final streamedResponse = await _httpClient.send(request);
      if (streamedResponse.statusCode != 200) {
        throw Exception(
            'Download failed with HTTP ${streamedResponse.statusCode}');
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      current = current.copyWith(totalBytes: contentLength);
      _tasks[fileId] = current;
      notifyListeners();

      final file = File(targetPath);
      sink = file.openWrite();

      Digest? computedDigest;
      final outputSink = ChunkedConversionSink<Digest>.withCallback((chunks) {
        if (chunks.isNotEmpty) computedDigest = chunks.single;
      });
      final hashInput = sha256.startChunkedConversion(outputSink);

      int bytesDownloaded = 0;
      int lastNotificationBytes = 0;

      await for (final chunk in streamedResponse.stream) {
        if (_cancelledMap[fileId] == true) {
          await sink.close();
          if (await file.exists()) await file.delete();
          current = current.copyWith(
            status: DownloadStatus.cancelled,
            errorMessage: 'Download cancelled by user',
          );
          _tasks[fileId] = current;
          notifyListeners();
          return;
        }

        if (_pausedMap[fileId] == true) {
          await sink.close();
          current = current.copyWith(
            status: DownloadStatus.paused,
            downloadedBytes: bytesDownloaded,
          );
          _tasks[fileId] = current;
          notifyListeners();
          return;
        }

        sink.add(chunk);
        hashInput.add(chunk);
        bytesDownloaded += chunk.length;

        // Throttle notifications: update UI every ~64KB or when total length is known
        if (bytesDownloaded - lastNotificationBytes > 64 * 1024 ||
            (contentLength > 0 && bytesDownloaded >= contentLength)) {
          lastNotificationBytes = bytesDownloaded;
          current = current.copyWith(downloadedBytes: bytesDownloaded);
          _tasks[fileId] = current;
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;
      hashInput.close();

      // Checksum verification
      if (checksumToVerify != null && checksumToVerify.isNotEmpty) {
        final computedHash = computedDigest?.toString() ?? '';
        if (computedHash.toLowerCase() != checksumToVerify.toLowerCase()) {
          if (await file.exists()) await file.delete();
          throw Exception(
              'Checksum verification mismatch: expected $checksumToVerify, got $computedHash');
        }
      }

      final completedTask = current.copyWith(
        status: DownloadStatus.downloaded,
        totalBytes: bytesDownloaded,
        downloadedBytes: bytesDownloaded,
        downloadedAt: DateTime.now(),
        source: DownloadSource.appDownload,
        isDiscovered: false,
        checksum: checksumToVerify,
      );

      _tasks[fileId] = completedTask;
      await localDb.saveDownload(completedTask);
      notifyListeners();
    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      debugPrint('DownloadManager error downloading $fileName: $e');
      final failedTask = current.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      _tasks[fileId] = failedTask;
      notifyListeners();
    }
  }

  /// Pauses an active download.
  void pauseDownload(String fileId) {
    if (_tasks[fileId]?.status == DownloadStatus.downloading) {
      _pausedMap[fileId] = true;
      _tasks[fileId] = _tasks[fileId]!.copyWith(status: DownloadStatus.paused);
      notifyListeners();
    }
  }

  /// Cancels an active or paused download.
  Future<void> cancelDownload(String fileId) async {
    _cancelledMap[fileId] = true;
    final task = _tasks[fileId];
    if (task != null) {
      try {
        final file = File(task.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      _tasks.remove(fileId);
      await localDb.removeDownload(fileId);
      notifyListeners();
    }
  }

  /// Resumes or retries a paused or failed download.
  Future<void> resumeDownload(String fileId) async {
    final task = _tasks[fileId];
    if (task != null) {
      await downloadBookFile(
        bookId: task.bookId,
        fileId: task.fileId,
        bookTitle: task.bookTitle,
        author: task.author,
        coverUrl: task.coverUrl,
        fileName: task.fileName,
        format: task.format,
        expectedChecksum: task.checksum,
      );
    }
  }

  /// Registers books discovered from the Downloads directory scan.
  /// Automatically prevents duplicate entries:
  /// - If a file was already downloaded through the app, preserve the app download!
  /// - Only registers new or discovered files.
  Future<void> registerDiscoveredBooks(List<DownloadTask> discovered) async {
    bool hasChanges = false;

    final existingPaths = <String, DownloadTask>{};
    for (final t in _tasks.values) {
      existingPaths[t.localPath.toLowerCase()] = t;
    }

    for (final disc in discovered) {
      final existingByPath = existingPaths[disc.localPath.toLowerCase()];
      final existingById = _tasks[disc.fileId];

      // If already present as an app download, preserve the app download!
      if (existingByPath != null && !existingByPath.isDiscovered) continue;
      if (existingById != null && !existingById.isDiscovered) continue;

      _tasks[disc.fileId] = disc;
      await localDb.saveDownload(disc);
      hasChanges = true;
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// Removes a downloaded book.
  /// If [deletePhysicalFile] is true, permanently deletes the file from storage.
  /// If false, removes the entry from the Downloads listing only, keeping the file on disk.
  /// IMPORTANT: Never removes or alters the book in the main library!
  Future<bool> removeDownload(
    String fileId, {
    bool deletePhysicalFile = false,
  }) async {
    final task = _tasks[fileId];
    if (task == null) return false;

    bool fileDeletionSuccess = true;

    if (deletePhysicalFile) {
      try {
        final file = File(task.localPath);
        if (await file.exists()) {
          await file.delete();
        }
        final parent = file.parent;
        if (await parent.exists() && (await parent.list().isEmpty)) {
          await parent.delete();
        }
      } catch (e) {
        debugPrint('Error deleting local file from storage: $e');
        fileDeletionSuccess = false;
      }
    }

    _tasks.remove(fileId);
    await localDb.removeDownload(fileId);
    notifyListeners();

    return fileDeletionSuccess;
  }

  /// Legacy alias: deletes file and removes record.
  Future<void> deleteDownload(String fileId) async {
    await removeDownload(fileId, deletePhysicalFile: true);
  }

  Future<void> clearAllDownloads() async {
    for (final task in _tasks.values.toList()) {
      try {
        final file = File(task.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    _tasks.clear();
    await localDb.clearAllDownloads();
    notifyListeners();
  }
}

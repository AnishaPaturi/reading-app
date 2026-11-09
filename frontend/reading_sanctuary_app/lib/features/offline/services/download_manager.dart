import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
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

    // Verify physical file existence on disk
    for (final entry in _tasks.entries.toList()) {
      if (entry.value.isCompleted) {
        final f = File(entry.value.localPath);
        if (!await f.exists()) {
          _tasks.remove(entry.key);
          await localDb.removeDownload(entry.key);
        }
      }
    }

    _initialized = true;
    notifyListeners();
  }

  DownloadTask? getTask(String fileId) => _tasks[fileId];

  bool isDownloaded(String fileId) {
    final task = _tasks[fileId];
    if (task == null || task.status != DownloadStatus.downloaded) return false;
    return File(task.localPath).existsSync();
  }

  String? getLocalFilePath(String fileId) {
    final task = _tasks[fileId];
    if (task != null && task.status == DownloadStatus.downloaded) {
      final f = File(task.localPath);
      if (f.existsSync()) return task.localPath;
    }
    return null;
  }

  Future<Uint8List?> getLocalFileBytes(String fileId) async {
    final path = getLocalFilePath(fileId);
    if (path == null) return null;
    final f = File(path);
    if (await f.exists()) {
      return await f.readAsBytes();
    }
    return null;
  }

  List<DownloadTask> getAllDownloads() {
    return _tasks.values.where((t) => t.status == DownloadStatus.downloaded).toList();
  }

  int calculateTotalStorageBytes() {
    int total = 0;
    for (final t in _tasks.values) {
      if (t.status == DownloadStatus.downloaded) {
        total += t.totalBytes;
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

  Future<void> downloadBookFile({
    required String bookId,
    required String fileId,
    required String bookTitle,
    required String fileName,
    required String format,
    String? directDownloadUrl,
    String? expectedChecksum,
  }) async {
    final targetDir = await _resolveDirectory(fileId);
    final targetPath = '$targetDir/$fileName';

    var current = DownloadTask(
      fileId: fileId,
      bookId: bookId,
      bookTitle: bookTitle,
      fileName: fileName,
      format: format,
      localPath: targetPath,
      status: DownloadStatus.downloading,
      checksum: expectedChecksum,
    );

    _tasks[fileId] = current;
    notifyListeners();

    try {
      String downloadUrl = directDownloadUrl ?? '';
      String? checksumToVerify = expectedChecksum;

      if (downloadUrl.isEmpty && storageApi != null) {
        final result = await storageApi!.getDownloadUrl(fileId);
        downloadUrl = result.downloadUrl;
        checksumToVerify ??= result.checksum;
      }

      if (downloadUrl.isEmpty) {
        // Fallback to standard book file endpoint
        final base = storageApi?.baseUrl ?? 'http://localhost:8080/api/v1';
        downloadUrl = '$base/books/$bookId/files/$fileId';
      }

      final uri = Uri.parse(downloadUrl);
      final token = storageApi?.tokenProvider();
      final headers = <String, String>{
        if (token != null && !downloadUrl.contains('X-Amz-Signature')) 'Authorization': 'Bearer $token',
      };

      final response = await _httpClient.get(uri, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Download failed with HTTP ${response.statusCode}');
      }

      final bytes = response.bodyBytes;

      // SHA-256 Checksum verification
      if (checksumToVerify != null && checksumToVerify.isNotEmpty) {
        final computedHash = sha256.convert(bytes).toString();
        if (computedHash.toLowerCase() != checksumToVerify.toLowerCase()) {
          throw Exception('Checksum verification mismatch: expected $checksumToVerify, got $computedHash');
        }
      }

      final file = File(targetPath);
      await file.writeAsBytes(bytes, flush: true);

      final completedTask = current.copyWith(
        status: DownloadStatus.downloaded,
        totalBytes: bytes.length,
        downloadedBytes: bytes.length,
        downloadedAt: DateTime.now(),
        checksum: checksumToVerify,
      );

      _tasks[fileId] = completedTask;
      await localDb.saveDownload(completedTask);
      notifyListeners();
    } catch (e) {
      debugPrint('DownloadManager error downloading $fileName: $e');
      final failedTask = current.copyWith(
        status: DownloadStatus.failed,
        errorMessage: e.toString(),
      );
      _tasks[fileId] = failedTask;
      notifyListeners();
    }
  }

  Future<void> deleteDownload(String fileId) async {
    final task = _tasks[fileId];
    if (task != null) {
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
        debugPrint('Error deleting local file: $e');
      }

      _tasks.remove(fileId);
      await localDb.removeDownload(fileId);
      notifyListeners();
    }
  }

  Future<void> clearAllDownloads() async {
    for (final task in _tasks.values.toList()) {
      try {
        final file = File(task.localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (ignored) {}
    }

    _tasks.clear();
    await localDb.clearAllDownloads();
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../domain/reading_progress.dart';

class ReadingProgressApi {
  final ApiClient _apiClient;

  ReadingProgressApi({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ReadingProgress?> getProgress(String bookFileId) async {
    try {
      final response = await _apiClient.get('/reading-progress/$bookFileId');
      if (response != null && response is Map<String, dynamic>) {
        return ReadingProgress.fromJson(response);
      }
      return null;
    } on NotFoundException {
      return null;
    } catch (e) {
      debugPrint('ReadingProgressApi.getProgress error for $bookFileId: $e');
      rethrow;
    }
  }

  Future<ReadingProgress> saveProgress(
    String bookFileId,
    ReadingProgress progress,
  ) async {
    try {
      final response = await _apiClient.put(
        '/reading-progress/$bookFileId',
        body: progress.toJson(),
      );
      if (response is Map<String, dynamic>) {
        return ReadingProgress.fromJson(response);
      }
      return progress;
    } catch (e) {
      debugPrint('ReadingProgressApi.saveProgress error for $bookFileId: $e');
      rethrow;
    }
  }

  Future<List<ReadingProgress>> getAllProgress() async {
    try {
      final response = await _apiClient.get('/reading-progress');
      if (response is List) {
        return response
            .whereType<Map<String, dynamic>>()
            .map((e) => ReadingProgress.fromJson(e))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('ReadingProgressApi.getAllProgress error: $e');
      rethrow;
    }
  }

  Future<void> resetProgress(String bookFileId) async {
    try {
      await _apiClient.delete('/reading-progress/$bookFileId');
    } catch (e) {
      debugPrint('ReadingProgressApi.resetProgress error for $bookFileId: $e');
      rethrow;
    }
  }
}

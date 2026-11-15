import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../domain/book_annotation.dart';

class AnnotationApi {
  final ApiClient _apiClient;

  AnnotationApi({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<BookAnnotation>> getAnnotationsByBookFile(String bookFileId) async {
    try {
      final res = await _apiClient.get('/annotations/book-file/$bookFileId');
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map((json) => BookAnnotation.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('AnnotationApi.getAnnotationsByBookFile failed: $e');
      rethrow;
    }
    return [];
  }

  Future<List<BookAnnotation>> getAnnotationsByBook(String bookId) async {
    try {
      final res = await _apiClient.get('/annotations/book/$bookId');
      if (res is List) {
        return res
            .whereType<Map<String, dynamic>>()
            .map((json) => BookAnnotation.fromJson(json))
            .toList();
      }
    } catch (e) {
      debugPrint('AnnotationApi.getAnnotationsByBook failed: $e');
      rethrow;
    }
    return [];
  }

  Future<BookAnnotation> createAnnotation(BookAnnotation annotation) async {
    final body = {
      'bookId': annotation.bookId,
      'bookFileId': annotation.bookFileId,
      'type': annotation.type.name.toUpperCase(),
      'selectedText': annotation.selectedText,
      'noteText': annotation.noteText,
      'color': annotation.color,
      'pageNumber': annotation.pageNumber,
      'locationData': jsonEncode(annotation.locationData),
    };

    final res = await _apiClient.post('/annotations', body: body);
    if (res is Map<String, dynamic>) {
      return BookAnnotation.fromJson(res);
    }
    throw Exception('Invalid response creating annotation');
  }

  Future<BookAnnotation> updateAnnotation(
    String id, {
    String? noteText,
    String? color,
  }) async {
    final body = <String, dynamic>{
      if (noteText != null) 'noteText': noteText,
      if (color != null) 'color': color,
    };

    final res = await _apiClient.patch('/annotations/$id', body: body);
    if (res is Map<String, dynamic>) {
      return BookAnnotation.fromJson(res);
    }
    throw Exception('Invalid response updating annotation');
  }

  Future<void> deleteAnnotation(String id) async {
    await _apiClient.delete('/annotations/$id');
  }
}

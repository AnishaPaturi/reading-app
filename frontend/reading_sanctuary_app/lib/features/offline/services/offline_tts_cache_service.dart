import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class OfflineTtsChapter {
  final int chapterIndex;
  final String title;
  final List<String> chunks;

  const OfflineTtsChapter({
    required this.chapterIndex,
    required this.title,
    required this.chunks,
  });

  factory OfflineTtsChapter.fromJson(Map<String, dynamic> json) {
    return OfflineTtsChapter(
      chapterIndex: (json['chapterIndex'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      chunks: (json['chunks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterIndex': chapterIndex,
      'title': title,
      'chunks': chunks,
    };
  }
}

class OfflineTtsDocument {
  final String fileId;
  final String bookId;
  final List<OfflineTtsChapter> chapters;

  const OfflineTtsDocument({
    required this.fileId,
    required this.bookId,
    required this.chapters,
  });

  factory OfflineTtsDocument.fromJson(Map<String, dynamic> json) {
    return OfflineTtsDocument(
      fileId: json['fileId']?.toString() ?? '',
      bookId: json['bookId']?.toString() ?? '',
      chapters: (json['chapters'] as List<dynamic>?)
              ?.map((e) => OfflineTtsChapter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'bookId': bookId,
      'chapters': chapters.map((c) => c.toJson()).toList(),
    };
  }
}

class OfflineTtsCacheService {
  final String? customCacheDirPath;
  final Map<String, OfflineTtsDocument> _memoryCache = {};

  OfflineTtsCacheService({this.customCacheDirPath});

  Future<File> _getFile(String fileId) async {
    if (customCacheDirPath != null) {
      final dir = Directory(customCacheDirPath!);
      if (!await dir.exists()) await dir.create(recursive: true);
      return File('${dir.path}/tts_$fileId.json');
    }
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/sanctuary_tts_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return File('${dir.path}/tts_$fileId.json');
  }

  Future<void> cacheExtractedDocument(OfflineTtsDocument doc) async {
    _memoryCache[doc.fileId] = doc;
    try {
      final file = await _getFile(doc.fileId);
      await file.writeAsString(jsonEncode(doc.toJson()));
    } catch (e) {
      debugPrint('Error caching offline TTS document: $e');
    }
  }

  Future<OfflineTtsDocument?> getCachedDocument(String fileId) async {
    if (_memoryCache.containsKey(fileId)) {
      return _memoryCache[fileId];
    }

    try {
      final file = await _getFile(fileId);
      if (await file.exists()) {
        final content = await file.readAsString();
        final doc = OfflineTtsDocument.fromJson(jsonDecode(content) as Map<String, dynamic>);
        _memoryCache[fileId] = doc;
        return doc;
      }
    } catch (e) {
      debugPrint('Error loading cached offline TTS document: $e');
    }

    return null;
  }

  Future<bool> hasCachedDocument(String fileId) async {
    if (_memoryCache.containsKey(fileId)) return true;
    try {
      final file = await _getFile(fileId);
      return await file.exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> removeCachedDocument(String fileId) async {
    _memoryCache.remove(fileId);
    try {
      final file = await _getFile(fileId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ArtworkPalette {
  final Color dominantColor;
  final Color vibrantColor;
  final Color mutedColor;
  final Color darkMutedColor;

  const ArtworkPalette({
    required this.dominantColor,
    required this.vibrantColor,
    required this.mutedColor,
    required this.darkMutedColor,
  });

  static const defaultPalette = ArtworkPalette(
    dominantColor: Color(0xFF2C1810),
    vibrantColor: Color(0xFFD4AF37),
    mutedColor: Color(0xFF8B7355),
    darkMutedColor: Color(0xFF1E140F),
  );
}

class OnlineCoverResult {
  final String title;
  final String? author;
  final String thumbnailUrl;
  final String fullCoverUrl;

  const OnlineCoverResult({
    required this.title,
    this.author,
    required this.thumbnailUrl,
    required this.fullCoverUrl,
  });
}

class AudiobookArtworkService {
  Directory? _artworkDir;
  final Uuid _uuid = const Uuid();

  Future<Directory> _getArtworkDirectory() async {
    if (_artworkDir != null) return _artworkDir!;
    final appDocs = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDocs.path}/audiobook_covers');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _artworkDir = dir;
    return dir;
  }

  /// Save extracted embedded artwork bytes into persistent app directory
  Future<String?> saveEmbeddedArtwork(Uint8List bytes, {String? extension = 'jpg'}) async {
    try {
      final dir = await _getArtworkDirectory();
      final fileName = 'cover_${_uuid.v4()}.$extension';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Error saving embedded artwork: $e');
      return null;
    }
  }

  /// Look for local cover image files in the audiobook folder
  Future<String?> findLocalCover(String folderPath) async {
    final folder = Directory(folderPath);
    if (!await folder.exists()) return null;

    final candidateNames = [
      'cover.jpg',
      'cover.png',
      'cover.jpeg',
      'folder.jpg',
      'folder.png',
      'front.jpg',
      'front.png',
      'artwork.jpg',
      'artwork.png',
    ];

    for (final name in candidateNames) {
      final file = File('${folder.path}/$name');
      if (await file.exists()) {
        return file.path;
      }
    }

    return null;
  }

  /// Save custom user-selected image file into persistent app directory
  Future<String?> saveCustomArtwork(String sourceFilePath) async {
    try {
      final source = File(sourceFilePath);
      if (!await source.exists()) return null;

      final dir = await _getArtworkDirectory();
      final ext = sourceFilePath.split('.').last.toLowerCase();
      final dest = File('${dir.path}/custom_${_uuid.v4()}.$ext');
      await source.copy(dest.path);
      return dest.path;
    } catch (e) {
      debugPrint('Error saving custom artwork: $e');
      return null;
    }
  }

  /// Search online covers using Open Library Books API
  Future<List<OnlineCoverResult>> searchOnlineCovers({
    required String title,
    String? author,
  }) async {
    try {
      final query = Uri.encodeComponent('$title ${author ?? ''}'.trim());
      final url = Uri.parse('https://openlibrary.org/search.json?q=$query&limit=8');
      final res = await http.get(url).timeout(const Duration(seconds: 8));

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final docs = data['docs'] as List<dynamic>? ?? [];
      final results = <OnlineCoverResult>[];

      for (final doc in docs) {
        final coverId = doc['cover_i'];
        if (coverId != null) {
          final bookTitle = doc['title'] as String? ?? title;
          final authors = doc['author_name'] as List<dynamic>?;
          final bookAuthor = authors != null && authors.isNotEmpty
              ? authors.first as String
              : author;

          results.add(OnlineCoverResult(
            title: bookTitle,
            author: bookAuthor,
            thumbnailUrl: 'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
            fullCoverUrl: 'https://covers.openlibrary.org/b/id/$coverId-L.jpg',
          ));
        }
      }

      return results;
    } catch (e) {
      debugPrint('Error searching online covers: $e');
      return [];
    }
  }

  /// Download and persist an online cover URL
  Future<String?> downloadAndSaveCover(String coverUrl) async {
    try {
      final res = await http.get(Uri.parse(coverUrl)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;

      return await saveEmbeddedArtwork(res.bodyBytes, extension: 'jpg');
    } catch (e) {
      debugPrint('Error downloading online cover: $e');
      return null;
    }
  }

  /// Extract palette colors from an image file
  Future<ArtworkPalette> extractPalette(String? coverPath) async {
    if (coverPath == null || coverPath.isEmpty) {
      return ArtworkPalette.defaultPalette;
    }

    try {
      ImageProvider provider;
      if (coverPath.startsWith('http://') || coverPath.startsWith('https://')) {
        provider = NetworkImage(coverPath);
      } else {
        final file = File(coverPath);
        if (!await file.exists()) {
          return ArtworkPalette.defaultPalette;
        }
        provider = FileImage(file);
      }

      final generator = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 16,
      );

      final dominant = generator.dominantColor?.color ??
          generator.darkMutedColor?.color ??
          ArtworkPalette.defaultPalette.dominantColor;
      final vibrant = generator.vibrantColor?.color ??
          generator.lightVibrantColor?.color ??
          ArtworkPalette.defaultPalette.vibrantColor;
      final muted = generator.mutedColor?.color ??
          generator.lightMutedColor?.color ??
          ArtworkPalette.defaultPalette.mutedColor;
      final darkMuted = generator.darkMutedColor?.color ??
          ArtworkPalette.defaultPalette.darkMutedColor;

      return ArtworkPalette(
        dominantColor: dominant,
        vibrantColor: vibrant,
        mutedColor: muted,
        darkMutedColor: darkMuted,
      );
    } catch (e) {
      debugPrint('Error extracting palette: $e');
      return ArtworkPalette.defaultPalette;
    }
  }
}

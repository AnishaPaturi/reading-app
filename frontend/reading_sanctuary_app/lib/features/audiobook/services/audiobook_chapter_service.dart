import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/datasources/audiobook_local_datasource.dart';
import '../data/models/audio_chapter.dart';
import '../data/models/audio_track.dart';

class AudiobookChapterService {
  final AudiobookLocalDatasource _localDatasource;
  final Uuid _uuid = const Uuid();

  AudiobookChapterService({AudiobookLocalDatasource? localDatasource})
      : _localDatasource = localDatasource ?? AudiobookLocalDatasource();

  /// Load chapters for a book, or generate default track-based chapters if none exist
  Future<List<AudioChapter>> getChaptersForBook(
    String bookId,
    List<AudioTrack> tracks,
  ) async {
    final stored = _localDatasource.getChaptersForBook(bookId);
    if (stored.isNotEmpty) return stored;

    // Fall back to generating track-as-chapter entries
    final generated = <AudioChapter>[];
    for (var i = 0; i < tracks.length; i++) {
      final t = tracks[i];
      generated.add(AudioChapter(
        id: _uuid.v4(),
        audiobookId: bookId,
        trackId: t.id,
        title: t.chapterTitle ?? t.fileName,
        start: Duration.zero,
        end: Duration(milliseconds: t.durationMs),
      ));
    }

    if (generated.isNotEmpty) {
      await _localDatasource.saveChaptersForBook(bookId, generated);
    }

    return generated;
  }

  /// Add a custom chapter marker
  Future<AudioChapter> addChapterMarker({
    required String bookId,
    required String trackId,
    required String title,
    required Duration start,
    required Duration end,
  }) async {
    final chapter = AudioChapter(
      id: _uuid.v4(),
      audiobookId: bookId,
      trackId: trackId,
      title: title,
      start: start,
      end: end,
    );

    final current = List<AudioChapter>.from(_localDatasource.getChaptersForBook(bookId));
    current.add(chapter);
    current.sort((a, b) => a.start.compareTo(b.start));

    await _localDatasource.saveChaptersForBook(bookId, current);
    return chapter;
  }

  /// Find active chapter by track ID and position
  AudioChapter? findCurrentChapter({
    required List<AudioChapter> chapters,
    required String currentTrackId,
    required Duration position,
  }) {
    for (final ch in chapters) {
      if (ch.trackId == currentTrackId && position >= ch.start && position < ch.end) {
        return ch;
      }
    }
    // Fallback: match by position if trackId is null
    for (final ch in chapters) {
      if (position >= ch.start && position < ch.end) {
        return ch;
      }
    }
    return chapters.isNotEmpty ? chapters.first : null;
  }
}

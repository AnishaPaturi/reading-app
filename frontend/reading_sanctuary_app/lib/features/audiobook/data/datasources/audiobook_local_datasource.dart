import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/audiobook.dart';
import '../models/audio_track.dart';
import '../models/audio_chapter.dart';
import '../models/playback_progress.dart';
import '../models/audiobook_bookmark.dart';
import '../models/listening_event.dart';
import '../models/audio_settings.dart';

class AudiobookLocalDatasource {
  final String? customDirectoryPath;
  Directory? _baseDir;
  bool _initialized = false;

  final Map<String, Audiobook> _audiobooks = {};
  final Map<String, List<AudioTrack>> _tracksByBook = {};
  final Map<String, List<AudioChapter>> _chaptersByBook = {};
  final Map<String, PlaybackProgress> _progress = {};
  final Map<String, List<AudiobookBookmark>> _bookmarksByBook = {};
  final List<ListeningSession> _sessions = [];
  final List<ListeningEvent> _events = [];
  AudioSettings _settings = const AudioSettings();

  AudiobookLocalDatasource({this.customDirectoryPath});

  Future<void> init() async {
    if (_initialized) return;

    try {
      if (customDirectoryPath != null) {
        _baseDir = Directory(customDirectoryPath!);
      } else {
        _baseDir = await getApplicationDocumentsDirectory();
      }

      if (!await _baseDir!.exists()) {
        await _baseDir!.create(recursive: true);
      }

      await _loadState();
    } catch (e) {
      debugPrint('AudiobookLocalDatasource init fallback to memory: $e');
    }

    _initialized = true;
  }

  File _getFile(String filename) {
    final path = _baseDir != null ? '${_baseDir!.path}/$filename' : filename;
    return File(path);
  }

  Future<void> _loadState() async {
    try {
      final bookFile = _getFile('sanctuary_audiobooks.json');
      if (await bookFile.exists()) {
        final content = await bookFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _audiobooks.clear();
        for (final item in list) {
          final book = Audiobook.fromJson(item as Map<String, dynamic>);
          _audiobooks[book.id] = book;
        }
      }

      final trackFile = _getFile('sanctuary_audio_tracks.json');
      if (await trackFile.exists()) {
        final content = await trackFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _tracksByBook.clear();
        for (final item in list) {
          final track = AudioTrack.fromJson(item as Map<String, dynamic>);
          _tracksByBook.putIfAbsent(track.audiobookId, () => []).add(track);
        }
        for (final list in _tracksByBook.values) {
          list.sort((a, b) => a.trackOrder.compareTo(b.trackOrder));
        }
      }

      final chapterFile = _getFile('sanctuary_audio_chapters.json');
      if (await chapterFile.exists()) {
        final content = await chapterFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _chaptersByBook.clear();
        for (final item in list) {
          final chapter = AudioChapter.fromJson(item as Map<String, dynamic>);
          if (chapter.audiobookId != null) {
            _chaptersByBook.putIfAbsent(chapter.audiobookId!, () => []).add(chapter);
          }
        }
      }

      final progressFile = _getFile('sanctuary_playback_progress.json');
      if (await progressFile.exists()) {
        final content = await progressFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _progress.clear();
        for (final item in list) {
          final p = PlaybackProgress.fromJson(item as Map<String, dynamic>);
          _progress[p.audiobookId] = p;
        }
      }

      final bookmarkFile = _getFile('sanctuary_audiobook_bookmarks.json');
      if (await bookmarkFile.exists()) {
        final content = await bookmarkFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _bookmarksByBook.clear();
        for (final item in list) {
          final bm = AudiobookBookmark.fromJson(item as Map<String, dynamic>);
          _bookmarksByBook.putIfAbsent(bm.audiobookId, () => []).add(bm);
        }
      }

      final sessionFile = _getFile('sanctuary_listening_sessions.json');
      if (await sessionFile.exists()) {
        final content = await sessionFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _sessions.clear();
        for (final item in list) {
          _sessions.add(ListeningSession.fromJson(item as Map<String, dynamic>));
        }
      }

      final eventFile = _getFile('sanctuary_listening_events.json');
      if (await eventFile.exists()) {
        final content = await eventFile.readAsString();
        final list = jsonDecode(content) as List<dynamic>;
        _events.clear();
        for (final item in list) {
          _events.add(ListeningEvent.fromJson(item as Map<String, dynamic>));
        }
      }

      final settingsFile = _getFile('sanctuary_audiobook_settings.json');
      if (await settingsFile.exists()) {
        final content = await settingsFile.readAsString();
        _settings = AudioSettings.fromJson(jsonDecode(content) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading local audiobook database: $e');
    }
  }

  Future<void> _saveBooks() async {
    try {
      final file = _getFile('sanctuary_audiobooks.json');
      final list = _audiobooks.values.map((b) => b.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving audiobooks: $e');
    }
  }

  Future<void> _saveTracks() async {
    try {
      final file = _getFile('sanctuary_audio_tracks.json');
      final allTracks = <Map<String, dynamic>>[];
      for (final list in _tracksByBook.values) {
        allTracks.addAll(list.map((t) => t.toJson()));
      }
      await file.writeAsString(jsonEncode(allTracks));
    } catch (e) {
      debugPrint('Error saving tracks: $e');
    }
  }

  Future<void> _saveChapters() async {
    try {
      final file = _getFile('sanctuary_audio_chapters.json');
      final allChapters = <Map<String, dynamic>>[];
      for (final list in _chaptersByBook.values) {
        allChapters.addAll(list.map((c) => c.toJson()));
      }
      await file.writeAsString(jsonEncode(allChapters));
    } catch (e) {
      debugPrint('Error saving chapters: $e');
    }
  }

  Future<void> _saveProgress() async {
    try {
      final file = _getFile('sanctuary_playback_progress.json');
      final list = _progress.values.map((p) => p.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final file = _getFile('sanctuary_audiobook_bookmarks.json');
      final allBookmarks = <Map<String, dynamic>>[];
      for (final list in _bookmarksByBook.values) {
        allBookmarks.addAll(list.map((b) => b.toJson()));
      }
      await file.writeAsString(jsonEncode(allBookmarks));
    } catch (e) {
      debugPrint('Error saving bookmarks: $e');
    }
  }

  Future<void> _saveSessions() async {
    try {
      final file = _getFile('sanctuary_listening_sessions.json');
      final list = _sessions.map((s) => s.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving sessions: $e');
    }
  }

  Future<void> _saveEvents() async {
    try {
      final file = _getFile('sanctuary_listening_events.json');
      final list = _events.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }

  Future<void> saveSettings(AudioSettings settings) async {
    _settings = settings;
    try {
      final file = _getFile('sanctuary_audiobook_settings.json');
      await file.writeAsString(jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('Error saving audiobook settings: $e');
    }
  }

  AudioSettings getSettings() => _settings;

  // Audiobooks CRUD
  List<Audiobook> getAllAudiobooks() => List.unmodifiable(_audiobooks.values);

  Audiobook? getAudiobook(String id) => _audiobooks[id];

  Future<void> saveAudiobook(Audiobook book, List<AudioTrack> tracks, {List<AudioChapter>? chapters}) async {
    await init();
    _audiobooks[book.id] = book;
    _tracksByBook[book.id] = List.from(tracks)..sort((a, b) => a.trackOrder.compareTo(b.trackOrder));
    if (chapters != null) {
      _chaptersByBook[book.id] = List.from(chapters);
      await _saveChapters();
    }
    await _saveBooks();
    await _saveTracks();
  }

  Future<void> updateAudiobook(Audiobook book) async {
    await init();
    _audiobooks[book.id] = book;
    await _saveBooks();
  }

  Future<void> deleteAudiobook(String id) async {
    await init();
    _audiobooks.remove(id);
    _tracksByBook.remove(id);
    _chaptersByBook.remove(id);
    _progress.remove(id);
    _bookmarksByBook.remove(id);
    await _saveBooks();
    await _saveTracks();
    await _saveChapters();
    await _saveProgress();
    await _saveBookmarks();
  }

  // Tracks
  List<AudioTrack> getTracksForBook(String bookId) {
    final list = _tracksByBook[bookId] ?? [];
    return List.unmodifiable(list);
  }

  // Chapters
  List<AudioChapter> getChaptersForBook(String bookId) {
    return List.unmodifiable(_chaptersByBook[bookId] ?? []);
  }

  Future<void> saveChaptersForBook(String bookId, List<AudioChapter> chapters) async {
    await init();
    _chaptersByBook[bookId] = List.from(chapters);
    await _saveChapters();
  }

  // Progress
  PlaybackProgress? getProgress(String bookId) => _progress[bookId];

  Future<void> saveProgressRecord(PlaybackProgress progress) async {
    await init();
    _progress[progress.audiobookId] = progress;
    // Also update audiobook status if appropriate
    final book = _audiobooks[progress.audiobookId];
    if (book != null) {
      final updatedStatus = progress.completed
          ? AudiobookStatus.completed
          : (progress.positionMs > 0 || progress.trackIndex > 0
              ? AudiobookStatus.current
              : AudiobookStatus.notStarted);
      if (book.status != updatedStatus) {
        _audiobooks[book.id] = book.copyWith(status: updatedStatus);
        await _saveBooks();
      }
    }
    await _saveProgress();
  }

  // Bookmarks
  List<AudiobookBookmark> getBookmarks(String bookId) {
    return List.unmodifiable(_bookmarksByBook[bookId] ?? []);
  }

  List<AudiobookBookmark> getAllBookmarks() {
    final all = <AudiobookBookmark>[];
    for (final list in _bookmarksByBook.values) {
      all.addAll(list);
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  Future<void> saveBookmark(AudiobookBookmark bookmark) async {
    await init();
    final list = _bookmarksByBook.putIfAbsent(bookmark.audiobookId, () => []);
    list.removeWhere((b) => b.id == bookmark.id);
    list.add(bookmark);
    await _saveBookmarks();
  }

  Future<void> deleteBookmark(String bookId, String bookmarkId) async {
    await init();
    final list = _bookmarksByBook[bookId];
    if (list != null) {
      list.removeWhere((b) => b.id == bookmarkId);
      await _saveBookmarks();
    }
  }

  // History & Sessions
  List<ListeningSession> getSessionsForBook(String bookId) {
    return _sessions.where((s) => s.audiobookId == bookId).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  List<ListeningSession> getAllSessions() {
    return List.unmodifiable(_sessions)..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  Future<void> recordSession(ListeningSession session) async {
    await init();
    _sessions.removeWhere((s) => s.id == session.id);
    _sessions.add(session);
    await _saveSessions();
  }

  Future<void> recordEvent(ListeningEvent event) async {
    await init();
    _events.add(event);
    await _saveEvents();
  }
}

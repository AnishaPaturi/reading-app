import 'dart:convert';
import '../models/audiobook.dart';
import '../models/audio_track.dart';
import '../models/audio_chapter.dart';
import '../models/playback_progress.dart';
import '../models/audiobook_bookmark.dart';
import '../models/listening_event.dart';
import '../models/audio_settings.dart';
import 'audiobook_storage.dart';

class AudiobookLocalDatasource {
  static const String _booksKey = 'sanctuary_audiobooks';
  static const String _tracksKey = 'sanctuary_audio_tracks';
  static const String _chaptersKey = 'sanctuary_audio_chapters';
  static const String _progressKey = 'sanctuary_playback_progress';
  static const String _bookmarksKey = 'sanctuary_audiobook_bookmarks';
  static const String _sessionsKey = 'sanctuary_listening_sessions';
  static const String _eventsKey = 'sanctuary_listening_events';
  static const String _settingsKey = 'sanctuary_audiobook_settings';

  final String? customDirectoryPath;
  final AudiobookStorageBackend _storage;
  bool _initialized = false;
  Future<void>? _initFuture;

  final Map<String, Audiobook> _audiobooks = {};
  final Map<String, List<AudioTrack>> _tracksByBook = {};
  final Map<String, List<AudioChapter>> _chaptersByBook = {};
  final Map<String, PlaybackProgress> _progress = {};
  final Map<String, List<AudiobookBookmark>> _bookmarksByBook = {};
  final List<ListeningSession> _sessions = [];
  final List<ListeningEvent> _events = [];
  AudioSettings _settings = const AudioSettings();

  AudiobookLocalDatasource({
    this.customDirectoryPath,
    AudiobookStorageBackend? storageBackend,
  }) : _storage = storageBackend ??
            createPlatformAudiobookStorage(customDirectoryPath: customDirectoryPath);

  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    if (_initFuture != null) {
      await _initFuture;
      return;
    }

    final future = _performInit();
    _initFuture = future;
    try {
      await future;
      _initialized = true;
    } catch (_) {
      _initFuture = null;
      _initialized = false;
      rethrow;
    }
  }

  Future<void> _performInit() async {
    await _storage.init();
    await _loadState();
  }

  Future<void> _loadState() async {
    final bookContent = await _storage.readStore(_booksKey);
    if (bookContent != null && bookContent.isNotEmpty) {
      final list = _decodeList(bookContent, _booksKey);
      _audiobooks.clear();
      for (final item in list) {
        final book = Audiobook.fromJson(item as Map<String, dynamic>);
        _audiobooks[book.id] = book;
      }
    }

    final trackContent = await _storage.readStore(_tracksKey);
    if (trackContent != null && trackContent.isNotEmpty) {
      final list = _decodeList(trackContent, _tracksKey);
      _tracksByBook.clear();
      for (final item in list) {
        final track = AudioTrack.fromJson(item as Map<String, dynamic>);
        _tracksByBook.putIfAbsent(track.audiobookId, () => []).add(track);
      }
      for (final trackList in _tracksByBook.values) {
        trackList.sort((a, b) => a.trackOrder.compareTo(b.trackOrder));
      }
    }

    final chapterContent = await _storage.readStore(_chaptersKey);
    if (chapterContent != null && chapterContent.isNotEmpty) {
      final list = _decodeList(chapterContent, _chaptersKey);
      _chaptersByBook.clear();
      for (final item in list) {
        final chapter = AudioChapter.fromJson(item as Map<String, dynamic>);
        if (chapter.audiobookId != null) {
          _chaptersByBook.putIfAbsent(chapter.audiobookId!, () => []).add(chapter);
        }
      }
    }

    final progressContent = await _storage.readStore(_progressKey);
    if (progressContent != null && progressContent.isNotEmpty) {
      final list = _decodeList(progressContent, _progressKey);
      _progress.clear();
      for (final item in list) {
        final p = PlaybackProgress.fromJson(item as Map<String, dynamic>);
        _progress[p.audiobookId] = p;
      }
    }

    final bookmarkContent = await _storage.readStore(_bookmarksKey);
    if (bookmarkContent != null && bookmarkContent.isNotEmpty) {
      final list = _decodeList(bookmarkContent, _bookmarksKey);
      _bookmarksByBook.clear();
      for (final item in list) {
        final bm = AudiobookBookmark.fromJson(item as Map<String, dynamic>);
        _bookmarksByBook.putIfAbsent(bm.audiobookId, () => []).add(bm);
      }
    }

    final sessionContent = await _storage.readStore(_sessionsKey);
    if (sessionContent != null && sessionContent.isNotEmpty) {
      final list = _decodeList(sessionContent, _sessionsKey);
      _sessions.clear();
      for (final item in list) {
        _sessions.add(ListeningSession.fromJson(item as Map<String, dynamic>));
      }
    }

    final eventContent = await _storage.readStore(_eventsKey);
    if (eventContent != null && eventContent.isNotEmpty) {
      final list = _decodeList(eventContent, _eventsKey);
      _events.clear();
      for (final item in list) {
        _events.add(ListeningEvent.fromJson(item as Map<String, dynamic>));
      }
    }

    final settingsContent = await _storage.readStore(_settingsKey);
    if (settingsContent != null && settingsContent.isNotEmpty) {
      try {
        _settings = AudioSettings.fromJson(jsonDecode(settingsContent) as Map<String, dynamic>);
      } catch (e) {
        throw AudiobookStorageException('Failed to parse persisted settings store', e);
      }
    }
  }

  List<dynamic> _decodeList(String content, String storeKey) {
    try {
      return jsonDecode(content) as List<dynamic>;
    } catch (e) {
      throw AudiobookStorageException('Failed to parse persisted store "$storeKey"', e);
    }
  }

  Future<void> _saveBooks() async {
    final list = _audiobooks.values.map((b) => b.toJson()).toList();
    await _storage.writeStore(_booksKey, jsonEncode(list));
  }

  Future<void> _saveTracks() async {
    final allTracks = <Map<String, dynamic>>[];
    for (final list in _tracksByBook.values) {
      allTracks.addAll(list.map((t) => t.toJson()));
    }
    await _storage.writeStore(_tracksKey, jsonEncode(allTracks));
  }

  Future<void> _saveChapters() async {
    final allChapters = <Map<String, dynamic>>[];
    for (final list in _chaptersByBook.values) {
      allChapters.addAll(list.map((c) => c.toJson()));
    }
    await _storage.writeStore(_chaptersKey, jsonEncode(allChapters));
  }

  Future<void> _saveProgress() async {
    final list = _progress.values.map((p) => p.toJson()).toList();
    await _storage.writeStore(_progressKey, jsonEncode(list));
  }

  Future<void> _saveBookmarks() async {
    final allBookmarks = <Map<String, dynamic>>[];
    for (final list in _bookmarksByBook.values) {
      allBookmarks.addAll(list.map((b) => b.toJson()));
    }
    await _storage.writeStore(_bookmarksKey, jsonEncode(allBookmarks));
  }

  Future<void> _saveSessions() async {
    final list = _sessions.map((s) => s.toJson()).toList();
    await _storage.writeStore(_sessionsKey, jsonEncode(list));
  }

  Future<void> _saveEvents() async {
    final list = _events.map((e) => e.toJson()).toList();
    await _storage.writeStore(_eventsKey, jsonEncode(list));
  }

  Future<void> saveSettings(AudioSettings settings) async {
    await init();
    final previous = _settings;
    _settings = settings;
    try {
      await _storage.writeStore(_settingsKey, jsonEncode(settings.toJson()));
    } catch (_) {
      _settings = previous;
      rethrow;
    }
  }

  AudioSettings getSettings() => _settings;

  // Audiobooks CRUD
  List<Audiobook> getAllAudiobooks() => List.unmodifiable(_audiobooks.values);

  Audiobook? getAudiobook(String id) => _audiobooks[id];

  Future<void> saveAudiobook(Audiobook book, List<AudioTrack> tracks, {List<AudioChapter>? chapters}) async {
    await init();
    final oldBook = _audiobooks[book.id];
    final oldTracks = _tracksByBook[book.id];
    final oldChapters = _chaptersByBook[book.id];

    _audiobooks[book.id] = book;
    _tracksByBook[book.id] = List<AudioTrack>.of(tracks)
      ..sort((a, b) => a.trackOrder.compareTo(b.trackOrder));
    if (chapters != null) {
      _chaptersByBook[book.id] = List<AudioChapter>.of(chapters);
    }

    try {
      if (chapters != null) {
        await _saveChapters();
      }
      await _saveBooks();
      await _saveTracks();
    } catch (e) {
      if (oldBook != null) {
        _audiobooks[book.id] = oldBook;
      } else {
        _audiobooks.remove(book.id);
      }
      if (oldTracks != null) {
        _tracksByBook[book.id] = oldTracks;
      } else {
        _tracksByBook.remove(book.id);
      }
      if (chapters != null) {
        if (oldChapters != null) {
          _chaptersByBook[book.id] = oldChapters;
        } else {
          _chaptersByBook.remove(book.id);
        }
      }
      rethrow;
    }
  }

  /// Safely and atomically replaces an existing audiobook's metadata and tracks.
  /// Preserves listening progress if safely mappable, or resets progress if [resetProgress] is true.
  /// If storage write fails, rolls back memory state and rethrows the exception.
  Future<void> replaceAudiobook({
    required Audiobook book,
    required List<AudioTrack> tracks,
    List<AudioChapter>? chapters,
    bool resetProgress = true,
  }) async {
    await init();
    final oldBook = _audiobooks[book.id];
    if (oldBook == null) {
      throw StateError('Cannot replace audiobook "${book.id}": not found in library.');
    }

    final oldTracks = _tracksByBook[book.id];
    final oldChapters = _chaptersByBook[book.id];
    final oldProgress = _progress[book.id];

    PlaybackProgress? updatedProgress;
    if (oldProgress != null) {
      if (resetProgress) {
        updatedProgress = PlaybackProgress(
          audiobookId: book.id,
          currentTrackId: tracks.isNotEmpty ? tracks.first.id : null,
          trackIndex: 0,
          positionMs: 0,
          totalDurationMs: book.totalDurationMs,
          playbackSpeed: oldProgress.playbackSpeed,
          lastListenedAt: DateTime.now(),
          completed: false,
        );
      } else {
        final trackIdx = oldProgress.trackIndex < tracks.length ? oldProgress.trackIndex : 0;
        final targetTrack = tracks.isNotEmpty ? tracks[trackIdx] : null;
        updatedProgress = oldProgress.copyWith(
          currentTrackId: targetTrack?.id,
          trackIndex: trackIdx,
          totalDurationMs: book.totalDurationMs,
        );
      }
    }

    _audiobooks[book.id] = book;
    _tracksByBook[book.id] = List<AudioTrack>.of(tracks)
      ..sort((a, b) => a.trackOrder.compareTo(b.trackOrder));
    if (chapters != null) {
      _chaptersByBook[book.id] = List<AudioChapter>.of(chapters);
    }
    if (updatedProgress != null) {
      _progress[book.id] = updatedProgress;
    }

    try {
      await _saveBooks();
      await _saveTracks();
      if (chapters != null) {
        await _saveChapters();
      }
      if (updatedProgress != null) {
        await _saveProgress();
      }
    } catch (e) {
      _audiobooks[book.id] = oldBook;
      if (oldTracks != null) {
        _tracksByBook[book.id] = oldTracks;
      } else {
        _tracksByBook.remove(book.id);
      }
      if (oldChapters != null) {
        _chaptersByBook[book.id] = oldChapters;
      } else {
        _chaptersByBook.remove(book.id);
      }
      if (oldProgress != null) {
        _progress[book.id] = oldProgress;
      } else {
        _progress.remove(book.id);
      }
      rethrow;
    }
  }

  Future<void> updateAudiobook(Audiobook book) async {
    await init();
    final oldBook = _audiobooks[book.id];
    _audiobooks[book.id] = book;
    try {
      await _saveBooks();
    } catch (_) {
      if (oldBook != null) {
        _audiobooks[book.id] = oldBook;
      } else {
        _audiobooks.remove(book.id);
      }
      rethrow;
    }
  }

  Future<void> deleteAudiobook(String id) async {
    await init();
    final oldBook = _audiobooks.remove(id);
    final oldTracks = _tracksByBook.remove(id);
    final oldChapters = _chaptersByBook.remove(id);
    final oldProgress = _progress.remove(id);
    final oldBookmarks = _bookmarksByBook.remove(id);
    try {
      await _saveBooks();
      await _saveTracks();
      await _saveChapters();
      await _saveProgress();
      await _saveBookmarks();
    } catch (_) {
      if (oldBook != null) _audiobooks[id] = oldBook;
      if (oldTracks != null) _tracksByBook[id] = oldTracks;
      if (oldChapters != null) _chaptersByBook[id] = oldChapters;
      if (oldProgress != null) _progress[id] = oldProgress;
      if (oldBookmarks != null) _bookmarksByBook[id] = oldBookmarks;
      rethrow;
    }
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
    final oldChapters = _chaptersByBook[bookId];
    _chaptersByBook[bookId] = List<AudioChapter>.of(chapters);
    try {
      await _saveChapters();
    } catch (_) {
      if (oldChapters != null) {
        _chaptersByBook[bookId] = oldChapters;
      } else {
        _chaptersByBook.remove(bookId);
      }
      rethrow;
    }
  }

  // Progress
  PlaybackProgress? getProgress(String bookId) => _progress[bookId];

  Future<void> saveProgressRecord(PlaybackProgress progress) async {
    await init();
    final oldProgress = _progress[progress.audiobookId];
    final book = _audiobooks[progress.audiobookId];
    _progress[progress.audiobookId] = progress;
    Audiobook? oldBook;
    if (book != null) {
      final updatedStatus = progress.completed
          ? AudiobookStatus.completed
          : (progress.positionMs > 0 || progress.trackIndex > 0
              ? AudiobookStatus.current
              : AudiobookStatus.notStarted);
      if (book.status != updatedStatus) {
        oldBook = book;
        _audiobooks[book.id] = book.copyWith(status: updatedStatus);
      }
    }
    try {
      if (oldBook != null) {
        await _saveBooks();
      }
      await _saveProgress();
    } catch (_) {
      if (oldProgress != null) {
        _progress[progress.audiobookId] = oldProgress;
      } else {
        _progress.remove(progress.audiobookId);
      }
      if (oldBook != null) {
        _audiobooks[oldBook.id] = oldBook;
      }
      rethrow;
    }
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
    return List.unmodifiable(all);
  }

  Future<void> saveBookmark(AudiobookBookmark bookmark) async {
    await init();
    final existingList = _bookmarksByBook[bookmark.audiobookId];
    final previousSnapshot = existingList != null ? List<AudiobookBookmark>.of(existingList) : null;
    final list = _bookmarksByBook.putIfAbsent(bookmark.audiobookId, () => []);
    list.removeWhere((b) => b.id == bookmark.id);
    list.add(bookmark);
    try {
      await _saveBookmarks();
    } catch (_) {
      if (previousSnapshot != null) {
        _bookmarksByBook[bookmark.audiobookId] = previousSnapshot;
      } else {
        _bookmarksByBook.remove(bookmark.audiobookId);
      }
      rethrow;
    }
  }

  Future<void> deleteBookmark(String bookId, String bookmarkId) async {
    await init();
    final list = _bookmarksByBook[bookId];
    if (list == null) return;
    final previousSnapshot = List<AudiobookBookmark>.of(list);
    list.removeWhere((b) => b.id == bookmarkId);
    try {
      await _saveBookmarks();
    } catch (_) {
      _bookmarksByBook[bookId] = previousSnapshot;
      rethrow;
    }
  }

  // History & Sessions
  List<ListeningSession> getSessionsForBook(String bookId) {
    final list = _sessions.where((s) => s.audiobookId == bookId).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(list);
  }

  List<ListeningSession> getAllSessions() {
    final list = List<ListeningSession>.of(_sessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(list);
  }

  Future<void> recordSession(ListeningSession session) async {
    await init();
    final previous = List<ListeningSession>.of(_sessions);
    _sessions.removeWhere((s) => s.id == session.id);
    _sessions.add(session);
    try {
      await _saveSessions();
    } catch (_) {
      _sessions
        ..clear()
        ..addAll(previous);
      rethrow;
    }
  }

  Future<void> recordEvent(ListeningEvent event) async {
    await init();
    final previous = List<ListeningEvent>.of(_events);
    _events.add(event);
    try {
      await _saveEvents();
    } catch (_) {
      _events
        ..clear()
        ..addAll(previous);
      rethrow;
    }
  }
}

import 'package:uuid/uuid.dart';
import '../data/datasources/audiobook_local_datasource.dart';
import '../data/models/audiobook_bookmark.dart';

class AudiobookBookmarkService {
  final AudiobookLocalDatasource _localDatasource;
  final Uuid _uuid = const Uuid();

  AudiobookBookmarkService({AudiobookLocalDatasource? localDatasource})
      : _localDatasource = localDatasource ?? AudiobookLocalDatasource();

  Future<AudiobookBookmark> createBookmark({
    required String audiobookId,
    String? trackId,
    int trackIndex = 0,
    required int positionMs,
    required String title,
    String? note,
    String category = 'note',
    bool isFavorite = false,
  }) async {
    final bookmark = AudiobookBookmark(
      id: _uuid.v4(),
      audiobookId: audiobookId,
      trackId: trackId,
      trackIndex: trackIndex,
      positionMs: positionMs,
      title: title.trim().isEmpty ? 'Bookmark at ${positionMs ~/ 1000}s' : title.trim(),
      note: note,
      category: category,
      isFavorite: isFavorite,
      createdAt: DateTime.now(),
    );

    await _localDatasource.saveBookmark(bookmark);
    return bookmark;
  }

  Future<void> updateBookmark(AudiobookBookmark bookmark) async {
    await _localDatasource.saveBookmark(bookmark);
  }

  Future<void> toggleFavorite(String bookId, String bookmarkId) async {
    final list = _localDatasource.getBookmarks(bookId);
    final match = list.where((b) => b.id == bookmarkId).firstOrNull;
    if (match != null) {
      final updated = match.copyWith(isFavorite: !match.isFavorite);
      await _localDatasource.saveBookmark(updated);
    }
  }

  Future<void> deleteBookmark(String bookId, String bookmarkId) async {
    await _localDatasource.deleteBookmark(bookId, bookmarkId);
  }

  List<AudiobookBookmark> getBookmarksForBook(String bookId, {String? categoryFilter, bool? onlyFavorites}) {
    var list = _localDatasource.getBookmarks(bookId);
    if (categoryFilter != null && categoryFilter != 'all') {
      list = list.where((b) => b.category.toLowerCase() == categoryFilter.toLowerCase()).toList();
    }
    if (onlyFavorites == true) {
      list = list.where((b) => b.isFavorite).toList();
    }
    return list;
  }

  List<AudiobookBookmark> getAllBookmarks({String? categoryFilter, bool? onlyFavorites}) {
    var list = _localDatasource.getAllBookmarks();
    if (categoryFilter != null && categoryFilter != 'all') {
      list = list.where((b) => b.category.toLowerCase() == categoryFilter.toLowerCase()).toList();
    }
    if (onlyFavorites == true) {
      list = list.where((b) => b.isFavorite).toList();
    }
    return list;
  }
}

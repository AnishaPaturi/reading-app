import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/audiobook_local_datasource.dart';
import '../../data/models/audiobook.dart';

class AudiobookLibraryFilter {
  final String query;
  final AudiobookStatus? status;
  final bool gridView;
  final String sortBy; // 'recentlyAdded', 'recentlyPlayed', 'title', 'author'

  const AudiobookLibraryFilter({
    this.query = '',
    this.status,
    this.gridView = true,
    this.sortBy = 'recentlyAdded',
  });

  AudiobookLibraryFilter copyWith({
    String? query,
    AudiobookStatus? status,
    bool clearStatus = false,
    bool? gridView,
    String? sortBy,
  }) {
    return AudiobookLibraryFilter(
      query: query ?? this.query,
      status: clearStatus ? null : (status ?? this.status),
      gridView: gridView ?? this.gridView,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class AudiobookLibraryFilterNotifier extends StateNotifier<AudiobookLibraryFilter> {
  AudiobookLibraryFilterNotifier() : super(const AudiobookLibraryFilter());

  void setQuery(String q) => state = state.copyWith(query: q);
  void setStatus(AudiobookStatus? s) => state = state.copyWith(status: s, clearStatus: s == null);
  void toggleGridView() => state = state.copyWith(gridView: !state.gridView);
  void setGridView(bool grid) => state = state.copyWith(gridView: grid);
  void setSortBy(String sort) => state = state.copyWith(sortBy: sort);
}

final audiobookLibraryFilterProvider =
    StateNotifierProvider<AudiobookLibraryFilterNotifier, AudiobookLibraryFilter>((ref) {
  return AudiobookLibraryFilterNotifier();
});

class AudiobookLibraryState {
  final List<Audiobook> allBooks;
  final bool isLoading;

  const AudiobookLibraryState({
    this.allBooks = const [],
    this.isLoading = false,
  });
}

class AudiobookLibraryNotifier extends StateNotifier<AudiobookLibraryState> {
  final AudiobookLocalDatasource _datasource;

  AudiobookLibraryNotifier(this._datasource) : super(const AudiobookLibraryState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = AudiobookLibraryState(allBooks: state.allBooks, isLoading: true);
    await _datasource.init();
    final books = _datasource.getAllAudiobooks();
    state = AudiobookLibraryState(allBooks: books, isLoading: false);
  }

  Future<void> deleteAudiobook(String id) async {
    await _datasource.deleteAudiobook(id);
    await refresh();
  }
}

final audiobookLibraryLocalDatasourceProvider = Provider<AudiobookLocalDatasource>((ref) {
  final ds = AudiobookLocalDatasource();
  return ds;
});

final audiobookLibraryProvider =
    StateNotifierProvider<AudiobookLibraryNotifier, AudiobookLibraryState>((ref) {
  final ds = ref.watch(audiobookLibraryLocalDatasourceProvider);
  return AudiobookLibraryNotifier(ds);
});

/// Filtered audiobooks derived provider
final filteredAudiobooksProvider = Provider<List<Audiobook>>((ref) {
  final libState = ref.watch(audiobookLibraryProvider);
  final filter = ref.watch(audiobookLibraryFilterProvider);

  var books = libState.allBooks;

  // Status filter
  if (filter.status != null) {
    books = books.where((b) => b.status == filter.status).toList();
  }

  // Text search (matches title and author)
  if (filter.query.trim().isNotEmpty) {
    final q = filter.query.toLowerCase().trim();
    books = books.where((b) {
      final titleMatch = b.title.toLowerCase().contains(q);
      final authorMatch = b.author.toLowerCase().contains(q);
      return titleMatch || authorMatch;
    }).toList();
  }

  // Sorting
  switch (filter.sortBy) {
    case 'title':
      books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      break;
    case 'author':
      books.sort((a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
      break;
    case 'recentlyAdded':
    default:
      books.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
      break;
  }

  return books;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/audiobook_local_datasource.dart';
import '../../data/models/audiobook.dart';
import 'audiobook_providers.dart';

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
  final String? errorMessage;

  const AudiobookLibraryState({
    this.allBooks = const [],
    this.isLoading = false,
    this.errorMessage,
  });
}

class AudiobookLibraryNotifier extends StateNotifier<AudiobookLibraryState> {
  final AudiobookLocalDatasource _datasource;

  AudiobookLibraryNotifier(this._datasource) : super(const AudiobookLibraryState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = AudiobookLibraryState(
      allBooks: state.allBooks,
      isLoading: true,
    );
    try {
      await _datasource.init();
      final books = List<Audiobook>.unmodifiable(_datasource.getAllAudiobooks());
      if (!mounted) return;
      state = AudiobookLibraryState(
        allBooks: books,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = AudiobookLibraryState(
        allBooks: state.allBooks,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> deleteAudiobook(String id) async {
    try {
      await _datasource.deleteAudiobook(id);
      await refresh();
    } catch (e) {
      if (!mounted) return;
      state = AudiobookLibraryState(
        allBooks: state.allBooks,
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final audiobookLibraryLocalDatasourceProvider = Provider<AudiobookLocalDatasource>((ref) {
  return ref.watch(audiobookLocalDatasourceProvider);
});

final audiobookLibraryProvider =
    StateNotifierProvider<AudiobookLibraryNotifier, AudiobookLibraryState>((ref) {
  final ds = ref.watch(audiobookLibraryLocalDatasourceProvider);
  return AudiobookLibraryNotifier(ds);
});

int _compareAudiobooks(Audiobook a, Audiobook b, String sortBy) {
  int cmp;
  switch (sortBy) {
    case 'title':
      cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      break;
    case 'author':
      cmp = a.author.toLowerCase().compareTo(b.author.toLowerCase());
      if (cmp == 0) {
        cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      break;
    case 'recentlyAdded':
    default:
      cmp = b.dateAdded.compareTo(a.dateAdded);
      break;
  }
  if (cmp != 0) return cmp;
  final dateCmp = b.dateAdded.compareTo(a.dateAdded);
  if (dateCmp != 0) return dateCmp;
  return a.id.compareTo(b.id);
}

/// Filters and deterministically sorts a copy of [source] without mutating it.
List<Audiobook> filterAndSortAudiobooks(
  List<Audiobook> source,
  AudiobookLibraryFilter filter, {
  AudiobookStatus? statusOverride,
}) {
  final effectiveStatus = statusOverride ?? filter.status;
  final trimmedQuery = filter.query.toLowerCase().trim();

  // Always allocate a fresh mutable list so unmodifiable sources are never sorted in place.
  final list = source.where((b) {
    if (effectiveStatus != null && b.status != effectiveStatus) {
      return false;
    }
    if (trimmedQuery.isNotEmpty) {
      final titleMatch = b.title.toLowerCase().contains(trimmedQuery);
      final authorMatch = b.author.toLowerCase().contains(trimmedQuery);
      if (!titleMatch && !authorMatch) {
        return false;
      }
    }
    return true;
  }).toList();

  list.sort((a, b) => _compareAudiobooks(a, b, filter.sortBy));
  return List<Audiobook>.unmodifiable(list);
}

/// Filtered audiobooks derived provider
final filteredAudiobooksProvider = Provider<List<Audiobook>>((ref) {
  final libState = ref.watch(audiobookLibraryProvider);
  final filter = ref.watch(audiobookLibraryFilterProvider);
  return filterAndSortAudiobooks(libState.allBooks, filter);
});

/// Derived provider for Currently listening audiobooks
final currentAudiobooksProvider = Provider<List<Audiobook>>((ref) {
  final libState = ref.watch(audiobookLibraryProvider);
  final filter = ref.watch(audiobookLibraryFilterProvider);
  return filterAndSortAudiobooks(
    libState.allBooks,
    filter,
    statusOverride: AudiobookStatus.current,
  );
});

/// Derived provider for Not Started audiobooks
final notStartedAudiobooksProvider = Provider<List<Audiobook>>((ref) {
  final libState = ref.watch(audiobookLibraryProvider);
  final filter = ref.watch(audiobookLibraryFilterProvider);
  return filterAndSortAudiobooks(
    libState.allBooks,
    filter,
    statusOverride: AudiobookStatus.notStarted,
  );
});

/// Derived provider for Completed audiobooks
final completedAudiobooksProvider = Provider<List<Audiobook>>((ref) {
  final libState = ref.watch(audiobookLibraryProvider);
  final filter = ref.watch(audiobookLibraryFilterProvider);
  return filterAndSortAudiobooks(
    libState.allBooks,
    filter,
    statusOverride: AudiobookStatus.completed,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/network_providers.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../data/models/bookshelf_model.dart';
import '../../data/repositories/bookshelf_repository.dart';
import '../../data/services/bookshelf_api_service.dart';

final bookshelfApiServiceProvider = Provider<BookshelfApiService>((ref) {
  return BookshelfApiService(apiClient: ref.watch(apiClientProvider));
});

final bookshelfRepositoryProvider = Provider<BookshelfRepository>((ref) {
  return BookshelfRepository(apiService: ref.watch(bookshelfApiServiceProvider));
});

class BookshelfListNotifier extends StateNotifier<AsyncValue<List<BookshelfModel>>> {
  final BookshelfRepository _repository;

  BookshelfListNotifier({required BookshelfRepository repository})
      : _repository = repository,
        super(const AsyncValue.loading()) {
    loadShelves();
  }

  Future<void> loadShelves({bool forceRefresh = false}) async {
    try {
      final shelves = await _repository.getShelves(forceRefresh: forceRefresh);
      state = AsyncValue.data(shelves);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<BookshelfModel> createShelf({
    required String name,
    String? description,
    String? color,
    String? themeColor,
    String? accentColor,
    String? icon,
    String? backgroundStyle,
    String? layoutStyle,
    bool? isFavorite,
    int? sortOrder,
  }) async {
    final created = await _repository.createShelf(
      name: name,
      description: description,
      color: color,
      themeColor: themeColor,
      accentColor: accentColor,
      icon: icon,
      backgroundStyle: backgroundStyle,
      layoutStyle: layoutStyle,
      isFavorite: isFavorite,
      sortOrder: sortOrder,
    );
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data([...current, created]);
    return created;
  }

  Future<BookshelfModel> updateShelf({
    required String shelfId,
    String? name,
    String? description,
    String? color,
    String? themeColor,
    String? accentColor,
    String? icon,
    String? backgroundStyle,
    String? layoutStyle,
    bool? isFavorite,
    int? sortOrder,
  }) async {
    final updated = await _repository.updateShelf(
      shelfId: shelfId,
      name: name,
      description: description,
      color: color,
      themeColor: themeColor,
      accentColor: accentColor,
      icon: icon,
      backgroundStyle: backgroundStyle,
      layoutStyle: layoutStyle,
      isFavorite: isFavorite,
      sortOrder: sortOrder,
    );
    final current = state.valueOrNull ?? [];
    final next = current.map((s) => s.id == shelfId ? updated : s).toList();
    state = AsyncValue.data(next);
    return updated;
  }

  Future<void> deleteShelf(String shelfId) async {
    await _repository.deleteShelf(shelfId);
    final current = state.valueOrNull ?? [];
    state = AsyncValue.data(current.where((s) => s.id != shelfId).toList());
  }

  Future<void> addBookToShelf(String shelfId, String bookId) async {
    await _repository.addBookToShelf(shelfId, bookId);
    final current = state.valueOrNull ?? [];
    final next = current.map((s) {
      if (s.id == shelfId) {
        if (!s.bookIds.contains(bookId)) {
          final nextIds = [...s.bookIds, bookId];
          return s.copyWith(bookIds: nextIds, bookCount: nextIds.length);
        }
      }
      return s;
    }).toList();
    state = AsyncValue.data(next);
  }

  Future<void> removeBookFromShelf(String shelfId, String bookId) async {
    await _repository.removeBookFromShelf(shelfId, bookId);
    final current = state.valueOrNull ?? [];
    final next = current.map((s) {
      if (s.id == shelfId) {
        final nextIds = s.bookIds.where((id) => id != bookId).toList();
        return s.copyWith(bookIds: nextIds, bookCount: nextIds.length);
      }
      return s;
    }).toList();
    state = AsyncValue.data(next);
  }
}

final bookshelfListNotifierProvider =
    StateNotifierProvider<BookshelfListNotifier, AsyncValue<List<BookshelfModel>>>((ref) {
  return BookshelfListNotifier(repository: ref.watch(bookshelfRepositoryProvider));
});

/// Returns a flat list of shelves or empty list if loading/error
final bookshelfListProvider = Provider<List<BookshelfModel>>((ref) {
  final asyncVal = ref.watch(bookshelfListNotifierProvider);
  return asyncVal.valueOrNull ?? [];
});

/// Family provider to fetch a single shelf by its ID
final bookshelfByIdProvider = Provider.family<BookshelfModel?, String>((ref, id) {
  final shelves = ref.watch(bookshelfListProvider);
  try {
    return shelves.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});

/// Family provider to get all Book entities belonging to a specific bookshelf
final booksByShelfProvider = Provider.family<List<Book>, String>((ref, shelfId) {
  final shelf = ref.watch(bookshelfByIdProvider(shelfId));
  if (shelf == null || shelf.bookIds.isEmpty) return [];
  final booksAsync = ref.watch(booksProvider);
  final allBooks = booksAsync.valueOrNull ?? [];
  final idsSet = shelf.bookIds.toSet();
  return allBooks.where((b) => idsSet.contains(b.id)).toList();
});

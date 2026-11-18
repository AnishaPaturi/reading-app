import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/network_providers.dart';
import '../models/book.dart';
import 'book_repository.dart';
import 'http_book_repository.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return HttpBookRepository(apiClient: ref.watch(apiClientProvider));
});

class BooksNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() => ref.read(bookRepositoryProvider).getBooks();

  Future<void> setStatus(
    String id,
    ReadingStatus status, {
    DateTime? dnfDate,
    String? dnfReason,
    String? dnfNotes,
  }) async {
    final repo = ref.read(bookRepositoryProvider);
    await repo.updateStatus(
      id,
      status,
      dnfDate: dnfDate,
      dnfReason: dnfReason,
      dnfNotes: dnfNotes,
    );
    state = AsyncData(await repo.getBooks());
  }

  Future<void> addBook(Book book) async {
    final repo = ref.read(bookRepositoryProvider);
    await repo.addBook(book);
    state = AsyncData(await repo.getBooks());
  }

  Future<void> setProgress(String id, double progress) async {
    final repo = ref.read(bookRepositoryProvider);
    await repo.updateProgress(id, progress);
    state = AsyncData(await repo.getBooks());
  }

  Future<void> setPage(String id, int page) async {
    final repo = ref.read(bookRepositoryProvider);
    await repo.setPage(id, page);
    state = AsyncData(await repo.getBooks());
  }

  Future<void> updateBookDetails(Book book) async {
    final repo = ref.read(bookRepositoryProvider);
    await repo.updateBookDetails(book);
    state = AsyncData(await repo.getBooks());
  }

  Future<void> moveToDeleted(String id) async {
    final repo = ref.read(bookRepositoryProvider);
    await repo.moveToDeleted(id);
    state = AsyncData(await repo.getBooks());
    ref.invalidate(deletedBooksProvider);
  }

  Future<void> restoreBook(String id) async {
    final repo = ref.read(bookRepositoryProvider);
    await repo.restoreBook(id);
    state = AsyncData(await repo.getBooks());
    ref.invalidate(deletedBooksProvider);
  }

  Future<void> permanentlyDeleteBook(String id) async {
    final repo = ref.read(bookRepositoryProvider);
    await repo.permanentlyDeleteBook(id);
    state = AsyncData(await repo.getBooks());
    ref.invalidate(deletedBooksProvider);
  }
}

final booksProvider = AsyncNotifierProvider<BooksNotifier, List<Book>>(BooksNotifier.new);

final deletedBooksProvider = FutureProvider<List<Book>>((ref) async {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.getDeletedBooks();
});

class SidebarCollapsed extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final sidebarCollapsedProvider = NotifierProvider<SidebarCollapsed, bool>(SidebarCollapsed.new);

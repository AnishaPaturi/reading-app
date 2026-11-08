import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import 'book_repository.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) => MockBookRepository());

class BooksNotifier extends AsyncNotifier<List<Book>> {
  @override
  Future<List<Book>> build() => ref.read(bookRepositoryProvider).getBooks();

  Future<void> setStatus(String id, ReadingStatus status) async {
    final repo = ref.read(bookRepositoryProvider);
    await repo.updateStatus(id, status);
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
}

final booksProvider = AsyncNotifierProvider<BooksNotifier, List<Book>>(BooksNotifier.new);

class SidebarCollapsed extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

final sidebarCollapsedProvider = NotifierProvider<SidebarCollapsed, bool>(SidebarCollapsed.new);

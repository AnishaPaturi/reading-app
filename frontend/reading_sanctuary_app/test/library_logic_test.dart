import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/utils/breakpoints.dart';
import 'package:reading_sanctuary_app/features/library/library_logic.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/book_repository.dart';

void main() {
  late List<Book> books;
  late MockBookRepository repo;

  setUp(() async {
    repo = MockBookRepository();
    books = await repo.getBooks();
  });

  test('sample data has at least 12 books', () => expect(books.length >= 12, true));

  test('search matches title, author and genre', () {
    expect(filterBooks(books, query: 'gatsby').length, 1);
    expect(filterBooks(books, query: 'clear').first.title, 'Atomic Habits');
    expect(filterBooks(books, query: 'mystery').length, 2);
    expect(filterBooks(books, query: 'zzz'), isEmpty);
  });

  test('status filters combine with search', () {
    final done = filterBooks(books, statuses: {ReadingStatus.completed});
    expect(done.every((b) => b.status == ReadingStatus.completed), true);
    expect(filterBooks(books, query: 'gatsby', statuses: {ReadingStatus.wantToRead}), isEmpty);
  });

  test('changing status to DNF keeps the book and its progress', () async {
    await repo.updateStatus('b1', ReadingStatus.dnf);
    final b = (await repo.getBooks()).firstWhere((x) => x.id == 'b1');
    expect(b.status, ReadingStatus.dnf);
    expect(b.progress, .42);
  });

  test('breakpoints', () {
    expect(Breakpoints.of(390), ScreenSize.mobile);
    expect(Breakpoints.of(768), ScreenSize.tablet);
    expect(Breakpoints.of(1440), ScreenSize.desktop);
  });
}

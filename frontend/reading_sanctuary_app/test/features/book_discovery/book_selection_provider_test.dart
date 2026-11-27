import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/classified_book.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/discovered_file.dart';
import 'package:reading_sanctuary_app/features/book_discovery/models/duplicate_status.dart';
import 'package:reading_sanctuary_app/features/book_discovery/providers/book_selection_provider.dart';

void main() {
  late BookSelectionNotifier notifier;

  ClassifiedBook createBook({
    required String id,
    required String name,
    required DuplicateClassification classification,
    int sizeBytes = 1048576, // 1 MB
  }) {
    return ClassifiedBook(
      file: DiscoveredFile(
        id: id,
        name: name,
        pathOrUri: '/books/$name',
        extension: 'epub',
        sizeBytes: sizeBytes,
        lastModified: DateTime(2026, 1, 1),
        parentFolderIdentifier: '/books',
      ),
      checksum: 'hash_$id',
      classification: classification,
      isValidFormat: classification != DuplicateClassification.invalid,
    );
  }

  setUp(() {
    notifier = BookSelectionNotifier();
  });

  test('Riverpod provider state: initial selection state is empty', () {
    expect(notifier.state, isEmpty);
    expect(notifier.isSelected('/books/any.epub'), isFalse);
  });

  test('Selection and deselection: selects importable book and deselects properly', () {
    final book = createBook(
      id: 'b1',
      name: 'valid.epub',
      classification: DuplicateClassification.newBook,
    );

    final selected = notifier.select(book);
    expect(selected, isTrue);
    expect(notifier.isSelected('/books/valid.epub'), isTrue);
    expect(notifier.state.length, 1);

    notifier.deselect('/books/valid.epub');
    expect(notifier.isSelected('/books/valid.epub'), isFalse);
    expect(notifier.state, isEmpty);
  });

  test('Toggle selection: toggles selection state of an importable book', () {
    final book = createBook(
      id: 'b1',
      name: 'toggle.epub',
      classification: DuplicateClassification.newBook,
    );

    final firstToggle = notifier.toggle(book);
    expect(firstToggle, isTrue);
    expect(notifier.isSelected('/books/toggle.epub'), isTrue);

    final secondToggle = notifier.toggle(book);
    expect(secondToggle, isFalse);
    expect(notifier.isSelected('/books/toggle.epub'), isFalse);
  });

  test('Select all eligible books: selects only importable books and ignores all others', () {
    final bNew1 = createBook(id: '1', name: 'new1.epub', classification: DuplicateClassification.newBook);
    final bNew2 = createBook(id: '2', name: 'new2.epub', classification: DuplicateClassification.newBook);
    final bImported = createBook(id: '3', name: 'imported.epub', classification: DuplicateClassification.alreadyImported);
    final bScanDup = createBook(id: '4', name: 'dup.epub', classification: DuplicateClassification.duplicateInScan);
    final bUnverified = createBook(id: '5', name: 'unverified.epub', classification: DuplicateClassification.verificationFailed);
    final bInvalid = createBook(id: '6', name: 'corrupted.epub', classification: DuplicateClassification.invalid);
    final bError = createBook(id: '7', name: 'locked.epub', classification: DuplicateClassification.error);

    final allBooks = [bNew1, bNew2, bImported, bScanDup, bUnverified, bInvalid, bError];

    final count = notifier.selectAllEligible(allBooks);

    expect(count, 2);
    expect(notifier.state.length, 2);
    expect(notifier.isSelected('/books/new1.epub'), isTrue);
    expect(notifier.isSelected('/books/new2.epub'), isTrue);
    expect(notifier.isSelected('/books/imported.epub'), isFalse);
    expect(notifier.isSelected('/books/unverified.epub'), isFalse);
  });

  test('Exclusion of non-importable classifications: rejects alreadyImported, duplicateInScan, verificationFailed, invalid, error', () {
    final bImported = createBook(id: '1', name: 'imported.epub', classification: DuplicateClassification.alreadyImported);
    final bScanDup = createBook(id: '2', name: 'dup.epub', classification: DuplicateClassification.duplicateInScan);
    final bUnverified = createBook(id: '3', name: 'unverified.epub', classification: DuplicateClassification.verificationFailed);
    final bInvalid = createBook(id: '4', name: 'corrupted.epub', classification: DuplicateClassification.invalid);
    final bError = createBook(id: '5', name: 'locked.epub', classification: DuplicateClassification.error);

    expect(notifier.select(bImported), isFalse);
    expect(notifier.select(bScanDup), isFalse);
    expect(notifier.select(bUnverified), isFalse);
    expect(notifier.select(bInvalid), isFalse);
    expect(notifier.select(bError), isFalse);

    expect(notifier.toggle(bImported), isFalse);
    expect(notifier.toggle(bUnverified), isFalse);

    expect(notifier.state, isEmpty);
  });

  test('Duplicate queue prevention: duplicate additions of same pathOrUri are idempotent', () {
    final book = createBook(id: '1', name: 'unique.epub', classification: DuplicateClassification.newBook);

    notifier.select(book);
    notifier.select(book);
    notifier.select(book);

    expect(notifier.state.length, 1);
  });

  test('Selected books metrics: computes total size in bytes and formatted string accurately', () {
    final b1 = createBook(id: '1', name: 'b1.epub', classification: DuplicateClassification.newBook, sizeBytes: 2097152); // 2 MB
    final b2 = createBook(id: '2', name: 'b2.epub', classification: DuplicateClassification.newBook, sizeBytes: 3145728); // 3 MB
    final allBooks = [b1, b2];

    notifier.select(b1);
    notifier.select(b2);

    final selectedBooks = notifier.getSelectedBooks(allBooks);
    expect(selectedBooks.length, 2);

    final totalBytes = notifier.getSelectedTotalBytes(allBooks);
    expect(totalBytes, 5242880); // 5 MB

    final formatted = notifier.getSelectedFormattedSize(allBooks);
    expect(formatted, '5.0 MB');
  });
}

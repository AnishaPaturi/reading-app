import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/screens/deleted_books_screen.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/book_delete_dialog.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/book_repository.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';

class TestBookRepository implements BookRepository {
  List<Book> activeBooks;
  List<Book> deletedBooks;
  String? lastRestoredId;
  String? lastPermanentlyDeletedId;
  String? lastMovedToDeletedId;

  TestBookRepository({
    this.activeBooks = const [],
    this.deletedBooks = const [],
  });

  @override
  Future<List<Book>> getBooks() async => List.unmodifiable(activeBooks);

  @override
  Future<List<Book>> getDeletedBooks() async => List.unmodifiable(deletedBooks);

  @override
  Future<void> updateStatus(
    String id,
    ReadingStatus status, {
    DateTime? dnfDate,
    String? dnfNotes,
    String? dnfReason,
  }) async {}

  @override
  Future<void> updateProgress(String id, double progress) async {}

  @override
  Future<void> addBook(Book book) async {
    activeBooks = [...activeBooks, book];
  }

  @override
  Future<void> moveToDeleted(String id) async {
    lastMovedToDeletedId = id;
    final book = activeBooks.firstWhere((b) => b.id == id);
    activeBooks = activeBooks.where((b) => b.id != id).toList();
    deletedBooks = [
      ...deletedBooks,
      book.copyWith(
        status: ReadingStatus.deleted,
        previousStatus: book.status,
        deletedAt: DateTime.now(),
      )
    ];
  }

  @override
  Future<void> restoreBook(String id) async {
    lastRestoredId = id;
    final book = deletedBooks.firstWhere((b) => b.id == id);
    deletedBooks = deletedBooks.where((b) => b.id != id).toList();
    activeBooks = [
      ...activeBooks,
      book.copyWith(
        status: book.previousStatus ?? ReadingStatus.wantToRead,
        clearDeletedMetadata: true,
      )
    ];
  }

  @override
  Future<void> permanentlyDeleteBook(String id) async {
    lastPermanentlyDeletedId = id;
    deletedBooks = deletedBooks.where((b) => b.id != id).toList();
  }
}

void main() {
  final sampleActiveBook = Book(
    id: 'book-1',
    title: 'The Secret History',
    author: 'Donna Tartt',
    genre: 'Dark Academia',
    description: 'A story of two minds',
    status: ReadingStatus.currentlyReading,
    progress: 0.45,
    pages: 559,
    formats: const [BookFormat.ebook],
    addedAt: DateTime(2026, 1, 1),
    coverColors: const [Color(0xFF2B3A55), Color(0xFF111A2B)],
  );

  final sampleDeletedBook = Book(
    id: 'book-deleted-1',
    title: 'The Picture of Dorian Gray',
    author: 'Oscar Wilde',
    genre: 'Gothic Classic',
    description: 'Philosophical gothic horror novel',
    status: ReadingStatus.deleted,
    previousStatus: ReadingStatus.currentlyReading,
    deletedAt: DateTime(2026, 2, 1),
    progress: 0.65,
    pages: 254,
    formats: const [BookFormat.ebook],
    addedAt: DateTime(2026, 1, 10),
    coverColors: const [Color(0xFF7A2E3B), Color(0xFF3A1219)],
  );

  group('BookDeleteDialog Tests', () {
    testWidgets('Renders dialog content and cancels without moving book', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await BookDeleteDialog.show(context, sampleActiveBook);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Move to Deleted?'), findsOneWidget);
      expect(find.textContaining('The Secret History'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
      expect(find.byType(BookDeleteDialog), findsNothing);
    });

    testWidgets('Confirms deletion and plays animation before resolving', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await BookDeleteDialog.show(context, sampleActiveBook);
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      // Advance animation partially
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete animation
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.byType(BookDeleteDialog), findsNothing);
    });
  });

  group('DeletedBooksScreen Tests', () {
    testWidgets('Displays empty state when no deleted books exist', (tester) async {
      final repo = TestBookRepository(deletedBooks: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: DeletedBooksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Deleted Books'), findsOneWidget);
      expect(find.text('The Forgotten Shelf is Empty'), findsOneWidget);
      expect(find.textContaining('Books you remove from your library will rest here'), findsOneWidget);
    });

    testWidgets('Renders deleted books with previous shelf tag and handles restore', (tester) async {
      final repo = TestBookRepository(
        activeBooks: [sampleActiveBook],
        deletedBooks: [sampleDeletedBook],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: DeletedBooksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('THE FORGOTTEN SHELF'), findsOneWidget);
      expect(find.text('The Picture of Dorian Gray'), findsWidgets);
      expect(find.text('Oscar Wilde'), findsOneWidget);
      expect(find.text('Previously: Currently Reading'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Delete Forever'), findsOneWidget);

      // Tap Restore
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();

      expect(repo.lastRestoredId, 'book-deleted-1');
      expect(find.textContaining('restored to Currently Reading'), findsOneWidget);
    });

    testWidgets('Handles permanent deletion flow with confirmation dialog', (tester) async {
      final repo = TestBookRepository(
        activeBooks: [],
        deletedBooks: [sampleDeletedBook],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: DeletedBooksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Delete Forever
      await tester.tap(find.text('Delete Forever'));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete Forever?'), findsOneWidget);
      expect(find.textContaining('permanently delete "The Picture of Dorian Gray"'), findsOneWidget);

      // Tap Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.lastPermanentlyDeletedId, isNull);

      // Tap Delete Forever again
      await tester.tap(find.text('Delete Forever'));
      await tester.pumpAndSettle();

      // Find the confirm button in the dialog
      final deleteForeverDialogBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Delete Forever'),
      );
      await tester.tap(deleteForeverDialogBtn);
      await tester.pumpAndSettle();

      expect(repo.lastPermanentlyDeletedId, 'book-deleted-1');
      expect(find.textContaining('was permanently removed.'), findsOneWidget);
    });
  });
}

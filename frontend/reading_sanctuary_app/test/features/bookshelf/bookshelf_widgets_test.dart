import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/widgets/book_cover.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/bookshelf_book_item.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/bookshelf_decoration.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/bookshelf_section.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';

void main() {
  final sampleBook1 = Book(
    id: 'test-1',
    title: 'Tempests & Tea Leaves',
    author: 'Rachel Morgan',
    genre: 'Fantasy',
    description: 'A magical tale',
    status: ReadingStatus.currentlyReading,
    progress: 0.45,
    pages: 320,
    formats: const [BookFormat.ebook],
    addedAt: DateTime.now(),
    coverColors: const [Color(0xFF8873DA), Color(0xFF6550C7)],
  );

  final sampleBook2 = Book(
    id: 'test-2',
    title: 'Secretly Yours',
    author: 'Tessa Bailey',
    genre: 'Romance',
    description: 'A charming romance',
    status: ReadingStatus.completed,
    progress: 1.0,
    pages: 368,
    formats: const [BookFormat.ebook],
    addedAt: DateTime.now(),
    coverColors: const [Color(0xFFE05A7A), Color(0xFF7E57C2)],
  );

  group('BookshelfBookItem Widget Tests', () {
    testWidgets('renders BookCover and triggers onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfBookItem(
              book: sampleBook1,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(BookCover), findsOneWidget);
      expect(find.byType(Tooltip), findsOneWidget);

      await tester.tap(find.byType(BookshelfBookItem));
      expect(tapped, isTrue);
    });

    testWidgets('renders completed badge when status is completed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookshelfBookItem(
              book: sampleBook2,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('BookshelfDecoration Widget Tests', () {
    testWidgets('renders all decoration types cleanly', (tester) async {
      for (final type in BookshelfDecorationType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BookshelfDecoration(type: type),
            ),
          ),
        );
        expect(find.byType(BookshelfDecoration), findsOneWidget);
      }
    });

    testWidgets('factory fromIndex cycles through decoration types', (tester) async {
      final dec0 = BookshelfDecoration.fromIndex(0);
      final dec1 = BookshelfDecoration.fromIndex(1);
      expect(dec0.type, BookshelfDecorationType.pottedPlant);
      expect(dec1.type, BookshelfDecorationType.flowerVase);
    });
  });

  group('BookshelfSection Widget Tests', () {
    testWidgets('renders shelf title, book count, horizontal books, and lilac plank', (tester) async {
      Book? clickedBook;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookshelfSection(
                title: 'Currently Reading',
                bookCount: 2,
                books: [sampleBook1, sampleBook2],
                icon: Icons.auto_stories_rounded,
                decorationType: BookshelfDecorationType.pottedPlant,
                onBookTap: (b) => clickedBook = b,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Currently Reading'), findsOneWidget);
      expect(find.text('2 books'), findsOneWidget);
      expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
      expect(find.byType(BookshelfBookItem), findsNWidgets(2));
      expect(find.byType(BookshelfDecoration), findsOneWidget);

      // Tap first book
      await tester.tap(find.byType(BookshelfBookItem).first);
      expect(clickedBook?.id, 'test-1');
    });

    testWidgets('renders empty shelf state when books list is empty', (tester) async {
      bool addTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BookshelfSection(
                title: 'Empty Shelf',
                books: const [],
                onBookTap: (_) {},
                onAddBooksTap: () => addTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('No books on this shelf yet'), findsOneWidget);
      expect(find.text('Add Books'), findsOneWidget);

      await tester.tap(find.text('Add Books'));
      expect(addTapped, isTrue);
    });
  });

  group('BookCover Widget Tests', () {
    testWidgets('renders styled procedural fallback when coverImageUrl is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 150,
                child: BookCover(book: sampleBook1),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tempests & Tea Leaves'), findsOneWidget);
      expect(find.text('RACHEL MORGAN'), findsOneWidget);
    });

    testWidgets('handles base64 data URI without throwing', (tester) async {
      // 1x1 transparent PNG base64
      const tinyPng = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      final bookWithBase64 = sampleBook1.copyWith(coverImageUrl: tinyPng);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100,
                height: 150,
                child: BookCover(book: bookWithBase64),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BookCover), findsOneWidget);
    });
  });
}

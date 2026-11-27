import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/widgets/book_cover.dart';
import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/recently_read_card.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';

void main() {
  group('BookCover Widget Tests', () {
    testWidgets('renders styled fallback when book has no cover', (tester) async {
      final book = Book(
        id: 'no-cover-id',
        title: 'Whispers in the Dark',
        author: 'Eleanor Vance',
        genre: 'Mystery',
        description: 'A dark mystery',
        status: ReadingStatus.wantToRead,
        progress: 0.0,
        pages: 280,
        formats: const [BookFormat.ebook],
        addedAt: DateTime(2026, 11, 20),
        coverColors: const [Color(0xFF8873DA), Color(0xFF6550C7)],
        hasCover: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 120,
                  height: 180,
                  child: BookCover(book: book),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Whispers in the Dark'), findsOneWidget);
      expect(find.text('ELEANOR VANCE'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders memory image when cover is a base64 data URI', (tester) async {
      // 1x1 transparent PNG as base64
      const transparentPngBase64 =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      final book = Book(
        id: 'cover-id',
        title: 'The Silent Patient',
        author: 'Alex Michaelides',
        genre: 'Thriller',
        description: 'A psychological thriller',
        status: ReadingStatus.currentlyReading,
        progress: 0.5,
        pages: 330,
        formats: const [BookFormat.ebook],
        addedAt: DateTime(2026, 11, 20),
        coverColors: const [Color(0xFF8873DA), Color(0xFF6550C7)],
        hasCover: true,
        coverImageUrl: transparentPngBase64,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 120,
                  height: 180,
                  child: BookCover(book: book),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('ClayBookMini delegates to BookCover when book is provided', (tester) async {
      const transparentPngBase64 =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      final book = Book(
        id: 'mini-cover-id',
        title: 'The Bone Year',
        author: 'Laura Anne Gilman',
        genre: 'Fantasy',
        description: 'A dark fantasy',
        status: ReadingStatus.currentlyReading,
        progress: 0.35,
        pages: 320,
        formats: const [BookFormat.ebook],
        addedAt: DateTime(2026, 11, 22),
        coverColors: const [Color(0xFF8873DA), Color(0xFF6550C7)],
        hasCover: true,
        coverImageUrl: transparentPngBase64,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClayBookMini(
                book: book,
                title: book.title,
                color: const Color(0xFF6550C7),
                width: 68,
                height: 96,
                hasHeart: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BookCover), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });

    testWidgets('RecentlyReadCard renders BookCover when book is provided', (tester) async {
      const transparentPngBase64 =
          'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

      final book = Book(
        id: 'recent-cover-id',
        title: 'The Bone Year',
        author: 'Laura Anne Gilman',
        genre: 'Fantasy',
        description: 'A dark fantasy',
        status: ReadingStatus.currentlyReading,
        progress: 0.35,
        pages: 320,
        formats: const [BookFormat.ebook],
        addedAt: DateTime(2026, 11, 22),
        coverColors: const [Color(0xFF8873DA), Color(0xFF6550C7)],
        hasCover: true,
        coverImageUrl: transparentPngBase64,
      );

      final item = RecentlyReadBook(
        title: book.title,
        imagePath: 'assets/images/dashboard/book_midnight.png',
        progress: book.progress,
        book: book,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: RecentlyReadCard(books: [item]),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BookCover), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('The Bone Year'), findsOneWidget);
    });
  });
}

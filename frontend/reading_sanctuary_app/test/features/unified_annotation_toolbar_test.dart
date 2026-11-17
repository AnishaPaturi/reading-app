import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/annotations/data/annotation_repository.dart';
import 'package:reading_sanctuary_app/features/annotations/domain/annotation_type.dart';
import 'package:reading_sanctuary_app/features/annotations/domain/book_annotation.dart';
import 'package:reading_sanctuary_app/features/annotations/presentation/screens/book_annotations_panel.dart';
import 'package:reading_sanctuary_app/features/annotations/presentation/widgets/annotation_context_menu.dart';
import 'package:reading_sanctuary_app/features/annotations/presentation/widgets/highlight_color_picker.dart';
import 'package:reading_sanctuary_app/features/annotations/providers/annotation_providers.dart';
import 'package:reading_sanctuary_app/features/reader/data/models/reader_annotations.dart';
import 'package:reading_sanctuary_app/features/reader/presentation/providers/reader_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../annotation_test.dart';
import '../reader_test.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Unified Annotation Toolbar Tests', () {
    testWidgets('Renders all 6 tools and triggers Highlight compact palette', (tester) async {
      HighlightColorOption? chosenHighlight;
      HighlightColorOption? chosenUnderline;
      bool noteClicked = false;
      bool quoteClicked = false;
      bool copyClicked = false;
      bool moreClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnnotationContextMenu(
                selectedText: 'Porcelain and lilac clay reading experience.',
                pageNumber: 42,
                onHighlight: (opt) => chosenHighlight = opt,
                onUnderline: (opt) => chosenUnderline = opt,
                onAddNote: () => noteClicked = true,
                onSaveQuote: () => quoteClicked = true,
                onCopy: () => copyClicked = true,
                onMore: () => moreClicked = true,
              ),
            ),
          ),
        ),
      );

      // Verify passage and page
      expect(find.text('“Porcelain and lilac clay reading experience.”'), findsOneWidget);
      expect(find.text('PAGE 42'), findsOneWidget);

      // Verify all 6 tools exist
      expect(find.text('Highlight'), findsOneWidget);
      expect(find.byIcon(Icons.format_underlined_rounded), findsWidgets);
      expect(find.text('Add Note'), findsOneWidget);
      expect(find.text('Quote'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);

      // Tap Underline tool
      await tester.tap(find.byIcon(Icons.format_underlined_rounded).last);
      await tester.pumpAndSettle();
      expect(chosenUnderline != null, isTrue);

      // Tap Add Note
      await tester.tap(find.text('Add Note'));
      await tester.pumpAndSettle();
      expect(noteClicked, isTrue);

      // Tap Quote
      await tester.tap(find.text('Quote'));
      await tester.pumpAndSettle();
      expect(quoteClicked, isTrue);

      // Tap Copy
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(copyClicked, isTrue);

      // Tap More
      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      expect(moreClicked, isTrue);

      // Now tap Highlight to open compact palette
      await tester.tap(find.text('Highlight'));
      await tester.pumpAndSettle();

      // Check that palette view is revealed
      expect(find.text('Select Highlight Colour'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Palette displays all 6 requested colors: Lavender, Lilac, Rose, Butter, Mint, Sky
      expect(HighlightColors.options.length, equals(6));
      expect(HighlightColors.options.map((o) => o.name).toList(), [
        'Lavender',
        'Lilac',
        'Rose',
        'Butter',
        'Mint',
        'Sky',
      ]);

      // Tap Mint color
      await tester.tap(find.byTooltip('Mint'));
      await tester.pumpAndSettle();
      expect(chosenHighlight?.name, equals('Mint'));
      expect(chosenHighlight?.hex, equals('#A4DFD0'));
    });

    testWidgets('HighlightColorPicker supports styles and clear selected indicator', (tester) async {
      HighlightStyle? chosenStyle;
      HighlightColorOption? chosenColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightColorPicker(
              selectedHex: '#C7B2F0', // Lilac
              showStyles: true,
              selectedStyle: HighlightStyle.underline,
              onColorSelected: (c) => chosenColor = c,
              onStyleSelected: (s) => chosenStyle = s,
            ),
          ),
        ),
      );

      // Selected color checkmark icon exists
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Style options exist
      expect(find.text('Solid'), findsOneWidget);
      expect(find.text('Underline'), findsOneWidget);
      expect(find.text('Wavy'), findsOneWidget);

      // Tap on Wavy style
      await tester.tap(find.text('Wavy'));
      await tester.pumpAndSettle();
      expect(chosenStyle, equals(HighlightStyle.wavy));

      // Tap on Sky color
      await tester.tap(find.byTooltip('Sky'));
      await tester.pumpAndSettle();
      expect(chosenColor?.name, equals('Sky'));
    });
  });

  group('Unified BookAnnotationsPanel with Bookmarks Tab Tests', () {
    testWidgets('Renders all 5 tabs and manages bookmarks', (tester) async {
      final fakeAnnoApi = FakeAnnotationApi();
      fakeAnnoApi.serverStore.add(
        BookAnnotation(
          id: 'h-1',
          bookId: 'book-100',
          bookFileId: 'file-100',
          type: AnnotationType.highlight,
          selectedText: 'A beautiful quote from the book',
          color: '#C7B2F0',
          pageNumber: 3,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final fakeReaderRepo = FakeReaderRepository();
      fakeReaderRepo.bookmarks.add(
        ReaderBookmark(
          id: 'bm-1',
          bookId: 'book-100',
          bookFileId: 'file-100',
          label: 'Chapter 2 Start',
          note: 'Important turning point',
          locationType: 'PDF_PAGE',
          locationValue: 'page=15',
          pageNumber: 15,
          createdAt: DateTime.now(),
        ),
      );

      final annoRepo = DefaultAnnotationRepository(api: fakeAnnoApi);
      ReaderBookmark? selectedBookmark;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            annotationRepositoryProvider.overrideWithValue(annoRepo),
            readerRepositoryProvider.overrideWithValue(fakeReaderRepo),
            readerBookmarksProvider('book-100').overrideWith((ref) async => fakeReaderRepo.bookmarks),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BookAnnotationsPanel(
                bookId: 'book-100',
                bookFileId: 'file-100',
                bookTitle: 'The Violet Sanctuary',
                currentPage: 3,
                onSelectAnnotation: (_) {},
                onSelectBookmark: (b) => selectedBookmark = b,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 5 tabs are displayed
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Highlights'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Bookmarks'), findsOneWidget);
      expect(find.text('Quotes'), findsOneWidget);

      // Switch to Bookmarks tab
      await tester.tap(find.text('Bookmarks'));
      await tester.pumpAndSettle();

      // Check bookmark content
      expect(find.text('Chapter 2 Start'), findsOneWidget);
      expect(find.text('Important turning point'), findsOneWidget);
      expect(find.text('Page 15'), findsOneWidget);

      // Tap bookmark card to navigate
      await tester.tap(find.text('Chapter 2 Start'));
      await tester.pumpAndSettle();

      expect(selectedBookmark?.id, equals('bm-1'));
      expect(selectedBookmark?.pageNumber, equals(15));
    });
  });
}

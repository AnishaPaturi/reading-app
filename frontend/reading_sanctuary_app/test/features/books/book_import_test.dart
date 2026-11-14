import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/books/data/book_file_validator.dart';
import 'package:reading_sanctuary_app/features/books/presentation/book_import_screen.dart';
import 'package:reading_sanctuary_app/features/books/providers/book_import_provider.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/add_books_sheet.dart';

void main() {
  group('BookFileValidator Tests', () {
    test('Validates supported formats: PDF, EPUB, M4A, MP3', () {
      expect(BookFileValidator.isSupported('book.pdf'), isTrue);
      expect(BookFileValidator.isSupported('book.PDF'), isTrue);
      expect(BookFileValidator.isSupported('novel.epub'), isTrue);
      expect(BookFileValidator.isSupported('audio.m4a'), isTrue);
      expect(BookFileValidator.isSupported('audio.mp3'), isTrue);
    });

    test('Rejects unsupported formats', () {
      expect(BookFileValidator.isSupported('script.sh'), isFalse);
      expect(BookFileValidator.isSupported('program.exe'), isFalse);
      expect(BookFileValidator.isSupported('notes.txt'), isFalse);
      expect(BookFileValidator.isSupported('archive.zip'), isFalse);
      expect(BookFileValidator.isSupported('noextension'), isFalse);
    });

    test('Returns correct MIME types and format strings', () {
      expect(BookFileValidator.getMimeType('book.pdf'), equals('application/pdf'));
      expect(BookFileValidator.getMimeType('book.epub'), equals('application/epub+zip'));
      expect(BookFileValidator.getMimeType('track.m4a'), equals('audio/mp4'));
      expect(BookFileValidator.getMimeType('audio.mp3'), equals('audio/mpeg'));

      expect(BookFileValidator.getFormat('book.pdf'), equals('PDF'));
      expect(BookFileValidator.getFormat('book.epub'), equals('EPUB'));
      expect(BookFileValidator.getFormat('track.m4a'), equals('M4A'));
      expect(BookFileValidator.getFormat('audio.mp3'), equals('MP3'));
    });
  });

  group('ImportFromDeviceTile Widget Tests', () {
    testWidgets('Renders Import from Device tile with format chips', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImportFromDeviceTile(
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Import from Device'), findsOneWidget);
      expect(find.text('Add your own PDF, EPUB or audiobook'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('EPUB'), findsOneWidget);
      expect(find.text('M4A'), findsOneWidget);
      expect(find.text('MP3'), findsOneWidget);

      await tester.tap(find.byType(ImportFromDeviceTile));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('BookImportScreen Widget Tests', () {
    testWidgets('Renders file details, title field, author field, reading status and import button for EPUB', (tester) async {
      final file = PlatformFile(
        name: 'The_Great_Gatsby.epub',
        size: 1024 * 512, // 512 KB
        bytes: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookImportScreen(
              selectedFile: file,
              shelfId: 'shelf-123',
            ),
          ),
        ),
      );

      expect(find.text('Import Book'), findsOneWidget);
      expect(find.text('The_Great_Gatsby.epub'), findsOneWidget);
      expect(find.text('The Great Gatsby'), findsOneWidget); // Cleans underscores
      expect(find.text('Author'), findsOneWidget);
      expect(find.text('Reading Status'), findsOneWidget);
      expect(find.text('Add to My Library'), findsOneWidget);
    });

    testWidgets('Renders Author / Narrator label for audio files', (tester) async {
      final file = PlatformFile(
        name: 'Sherlock_Holmes.mp3',
        size: 1024 * 1024 * 10, // 10 MB
        bytes: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BookImportScreen(
              selectedFile: file,
            ),
          ),
        ),
      );

      expect(find.text('Author / Narrator'), findsOneWidget);
    });
  });

  group('BookImportState Tests', () {
    test('Initial state is idle with 0.0 progress', () {
      const state = BookImportState();
      expect(state.status, equals(BookImportStatus.idle));
      expect(state.uploadProgress, equals(0.0));
      expect(state.errorMessage, isNull);
      expect(state.importedBook, isNull);
    });

    test('copyWith updates state correctly', () {
      const state = BookImportState();
      final updated = state.copyWith(
        status: BookImportStatus.uploading,
        uploadProgress: 0.5,
        errorMessage: 'Test error',
      );

      expect(updated.status, equals(BookImportStatus.uploading));
      expect(updated.uploadProgress, equals(0.5));
      expect(updated.errorMessage, equals('Test error'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/annotations/data/annotation_api.dart';
import 'package:reading_sanctuary_app/features/annotations/data/annotation_repository.dart';
import 'package:reading_sanctuary_app/features/annotations/domain/annotation_type.dart';
import 'package:reading_sanctuary_app/features/annotations/domain/book_annotation.dart';
import 'package:reading_sanctuary_app/features/annotations/presentation/screens/book_annotations_panel.dart';
import 'package:reading_sanctuary_app/features/annotations/presentation/widgets/annotation_context_menu.dart';
import 'package:reading_sanctuary_app/features/annotations/presentation/widgets/highlight_color_picker.dart';
import 'package:reading_sanctuary_app/features/annotations/providers/annotation_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAnnotationApi implements AnnotationApi {
  final List<BookAnnotation> serverStore = [];
  bool shouldThrow = false;

  @override
  Future<List<BookAnnotation>> getAnnotationsByBookFile(String bookFileId) async {
    if (shouldThrow) throw Exception('Network error');
    return serverStore.where((a) => a.bookFileId == bookFileId).toList();
  }

  @override
  Future<List<BookAnnotation>> getAnnotationsByBook(String bookId) async {
    if (shouldThrow) throw Exception('Network error');
    return serverStore.where((a) => a.bookId == bookId).toList();
  }

  @override
  Future<BookAnnotation> createAnnotation(BookAnnotation annotation) async {
    if (shouldThrow) throw Exception('Network error');
    final saved = annotation.copyWith(
      id: 'server-${annotation.id}',
      isPendingSync: false,
    );
    serverStore.add(saved);
    return saved;
  }

  @override
  Future<BookAnnotation> updateAnnotation(
    String id, {
    String? noteText,
    String? color,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    final idx = serverStore.indexWhere((a) => a.id == id);
    if (idx != -1) {
      final updated = serverStore[idx].copyWith(
        noteText: noteText,
        color: color,
        updatedAt: DateTime.now(),
      );
      serverStore[idx] = updated;
      return updated;
    }
    return BookAnnotation(
      id: id,
      bookId: 'b1',
      bookFileId: 'bf1',
      type: AnnotationType.highlight,
      noteText: noteText,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteAnnotation(String id) async {
    if (shouldThrow) throw Exception('Network error');
    serverStore.removeWhere((a) => a.id == id);
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BookAnnotation & NormalizedRect Domain Model Tests', () {
    test('NormalizedRect correctly computes absolute rectangle', () {
      const norm = NormalizedRect(left: 0.1, top: 0.2, width: 0.5, height: 0.3);
      const pageRect = Rect.fromLTWH(50, 100, 400, 600);

      final abs = norm.toAbsoluteRect(pageRect);

      expect(abs.left, equals(50 + 0.1 * 400));
      expect(abs.top, equals(100 + 0.2 * 600));
      expect(abs.width, equals(0.5 * 400));
      expect(abs.height, equals(0.3 * 600));
    });

    test('BookAnnotation displayColor parsing and defaults', () {
      final yellowAnno = BookAnnotation(
        id: '1',
        bookId: 'b1',
        bookFileId: 'bf1',
        type: AnnotationType.highlight,
        color: '#F5E7A8',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(yellowAnno.displayColor, equals(const Color(0xFFF5E7A8)));

      final defaultColorAnno = BookAnnotation(
        id: '2',
        bookId: 'b1',
        bookFileId: 'bf1',
        type: AnnotationType.highlight,
        color: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(defaultColorAnno.displayColor, equals(const Color(0xFFF5E7A8)));
    });

    test('BookAnnotation JSON serialization round-trip', () {
      final now = DateTime.now();
      final anno = BookAnnotation(
        id: 'anno-123',
        bookId: 'b-99',
        bookFileId: 'bf-42',
        type: AnnotationType.highlight,
        selectedText: 'The ancient library stood quiet in the moonlight.',
        noteText: 'A powerful opening reflection.',
        color: '#E6DEF8',
        pageNumber: 15,
        locationData: {
          'rectangles': [
            {'left': 0.1, 'top': 0.2, 'width': 0.4, 'height': 0.05}
          ],
          'cfi': 'epubcfi(/6/4!/4/2/1:0)',
        },
        createdAt: now,
        updatedAt: now,
      );

      final json = anno.toJson();
      final fromJson = BookAnnotation.fromJson(json);

      expect(fromJson.id, equals('anno-123'));
      expect(fromJson.bookId, equals('b-99'));
      expect(fromJson.bookFileId, equals('bf-42'));
      expect(fromJson.type, equals(AnnotationType.highlight));
      expect(fromJson.selectedText, equals('The ancient library stood quiet in the moonlight.'));
      expect(fromJson.noteText, equals('A powerful opening reflection.'));
      expect(fromJson.color, equals('#E6DEF8'));
      expect(fromJson.pageNumber, equals(15));
      expect(fromJson.normalizedRects.length, equals(1));
      expect(fromJson.normalizedRects.first.left, equals(0.1));
      expect(fromJson.epubCfi, equals('epubcfi(/6/4!/4/2/1:0)'));
    });
  });

  group('DefaultAnnotationRepository Tests', () {
    test('Saves annotation locally with pending sync and syncs to API', () async {
      final fakeApi = FakeAnnotationApi();
      final repo = DefaultAnnotationRepository(api: fakeApi);

      final localAnno = BookAnnotation(
        id: 'loc-1',
        bookId: 'b1',
        bookFileId: 'bf1',
        type: AnnotationType.highlight,
        selectedText: 'Passage to remember',
        color: '#F5E7A8',
        pageNumber: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Simulate offline: API throws
      fakeApi.shouldThrow = true;
      await repo.saveAnnotation(localAnno);

      // Verify stored locally with pending sync
      final localList = await repo.getAnnotations('bf1');
      expect(localList.length, equals(1));
      expect(localList.first.selectedText, equals('Passage to remember'));
      expect(localList.first.isPendingSync, isTrue);

      // Now back online: sync pending annotations
      fakeApi.shouldThrow = false;
      await repo.syncPendingAnnotations();

      expect(fakeApi.serverStore.length, equals(1));
      expect(fakeApi.serverStore.first.selectedText, equals('Passage to remember'));
    });

    test('Deletes annotation locally and syncs deletion to API', () async {
      final fakeApi = FakeAnnotationApi();
      fakeApi.serverStore.add(
        BookAnnotation(
          id: 'server-del-1',
          bookId: 'b1',
          bookFileId: 'bf1',
          type: AnnotationType.note,
          noteText: 'Note to be removed',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final repo = DefaultAnnotationRepository(api: fakeApi);

      // Initial fetch loads from server and caches
      final initial = await repo.getAnnotations('bf1');
      expect(initial.length, equals(1));

      // Delete locally
      await repo.deleteAnnotation('server-del-1', 'bf1');

      final afterDelete = await repo.getAnnotations('bf1');
      expect(afterDelete.isEmpty, isTrue);

      // Sync deletion
      await repo.syncPendingAnnotations();
      expect(fakeApi.serverStore.isEmpty, isTrue);
    });
  });

  group('BookAnnotationsProvider Notifier Tests', () {
    test('Optimistically adds highlight and note', () async {
      final fakeApi = FakeAnnotationApi();
      final repo = DefaultAnnotationRepository(api: fakeApi);

      final container = ProviderContainer(
        overrides: [
          annotationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      const params = BookAnnotationParams(bookId: 'b1', bookFileId: 'bf1');
      // Wait for initial load to complete
      await container.read(bookFileAnnotationsProvider(params).notifier).load();

      // Add highlight
      await container.read(bookFileAnnotationsProvider(params).notifier).addHighlight(
            selectedText: 'Highlight test',
            pageNumber: 5,
            color: '#F5E7A8',
          );

      var list = container.read(bookFileAnnotationsProvider(params)).value ?? [];
      expect(list.length, equals(1));
      expect(list.first.type, equals(AnnotationType.highlight));
      expect(list.first.selectedText, equals('Highlight test'));

      // Add standalone note
      await container.read(bookFileAnnotationsProvider(params).notifier).addNote(
            noteText: 'Important note on chapter 2',
            pageNumber: 5,
          );

      list = container.read(bookFileAnnotationsProvider(params)).value ?? [];
      expect(list.length, equals(2));
      expect(list.any((a) => a.type == AnnotationType.note), isTrue);
    });

    test('Optimistically updates and deletes annotation', () async {
      final fakeApi = FakeAnnotationApi();
      final repo = DefaultAnnotationRepository(api: fakeApi);

      final container = ProviderContainer(
        overrides: [
          annotationRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      const params = BookAnnotationParams(bookId: 'b1', bookFileId: 'bf1');
      await container.read(bookFileAnnotationsProvider(params).notifier).load();

      final created = await container.read(bookFileAnnotationsProvider(params).notifier).addNote(
            noteText: 'Initial text',
            pageNumber: 1,
          );

      // Update note and color
      await container.read(bookFileAnnotationsProvider(params).notifier).updateNote(
            id: created.id,
            noteText: 'Updated thoughts',
          );
      await container.read(bookFileAnnotationsProvider(params).notifier).updateColor(
            id: created.id,
            color: '#D2E8D4',
          );

      var list = container.read(bookFileAnnotationsProvider(params)).value ?? [];
      expect(list.first.noteText, equals('Updated thoughts'));
      expect(list.first.color, equals('#D2E8D4'));

      // Delete
      await container.read(bookFileAnnotationsProvider(params).notifier).deleteAnnotation(created.id);

      list = container.read(bookFileAnnotationsProvider(params)).value ?? [];
      expect(list.isEmpty, isTrue);
    });
  });

  group('Annotation UI Widgets Tests', () {
    testWidgets('HighlightColorPicker displays all color options', (tester) async {
      HighlightColorOption? chosen;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HighlightColorPicker(
              selectedHex: '#F5E7A8',
              onColorSelected: (c) => chosen = c,
            ),
          ),
        ),
      );

      expect(find.byType(HighlightColorPicker), findsOneWidget);
      expect(HighlightColors.options.length, equals(6));

      // Tap on Rose (third option, index 2)
      await tester.tap(find.byType(GestureDetector).at(2));
      await tester.pumpAndSettle();

      expect(chosen?.hex, equals('#FAD4D8'));
    });

    testWidgets('AnnotationContextMenu displays selected text and actions', (tester) async {
      bool noteClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnotationContextMenu(
              selectedText: 'A quoted sentence of great beauty.',
              pageNumber: 12,
              onHighlight: (_) {},
              onAddNote: () => noteClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('“A quoted sentence of great beauty.”'), findsOneWidget);
      expect(find.text('Add Note'), findsOneWidget);
      expect(find.text('PAGE 12'), findsOneWidget);

      await tester.tap(find.text('Add Note'));
      await tester.pump();
      expect(noteClicked, isTrue);
    });

    testWidgets('BookAnnotationsPanel renders tabs and items', (tester) async {
      final fakeApi = FakeAnnotationApi();
      fakeApi.serverStore.addAll([
        BookAnnotation(
          id: 'h1',
          bookId: 'b1',
          bookFileId: 'bf1',
          type: AnnotationType.highlight,
          selectedText: 'First highlighted quote',
          color: '#F5E7A8',
          pageNumber: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        BookAnnotation(
          id: 'n1',
          bookId: 'b1',
          bookFileId: 'bf1',
          type: AnnotationType.note,
          noteText: 'A thoughtful reflection on page 4',
          pageNumber: 4,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      final repo = DefaultAnnotationRepository(api: fakeApi);

      BookAnnotation? selectedAnnotation;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            annotationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BookAnnotationsPanel(
                bookId: 'b1',
                bookFileId: 'bf1',
                bookTitle: 'Test Novel',
                currentPage: 4,
                onSelectAnnotation: (a) => selectedAnnotation = a,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and tabs
      expect(find.text('My Annotations'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Highlights'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Bookmarks'), findsOneWidget);
      expect(find.text('Quotes'), findsOneWidget);

      // Check content
      expect(find.text('“First highlighted quote”'), findsOneWidget);
      expect(find.text('A thoughtful reflection on page 4'), findsOneWidget);

      // Tap on first annotation card jump button
      await tester.tap(find.text('Page 4').first);
      await tester.pumpAndSettle();

      expect(selectedAnnotation != null, isTrue);
    });
  });
}

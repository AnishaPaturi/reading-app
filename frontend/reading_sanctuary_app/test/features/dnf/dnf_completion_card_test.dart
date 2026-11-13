import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/dnf/models/dnf_completion_data.dart';
import 'package:reading_sanctuary_app/features/dnf/widgets/dnf_completion_card.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/book_repository.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';

class MockBookRepo implements BookRepository {
  List<Book> books;
  String? updatedId;
  ReadingStatus? updatedStatus;
  String? updatedReason;

  MockBookRepo(this.books);

  @override
  Future<List<Book>> getBooks() async => books;

  @override
  Future<void> updateStatus(
    String id,
    ReadingStatus status, {
    DateTime? dnfDate,
    String? dnfNotes,
    String? dnfReason,
  }) async {
    updatedId = id;
    updatedStatus = status;
    updatedReason = dnfReason;
  }

  @override
  Future<void> updateProgress(String id, double progress) async {}

  @override
  Future<void> addBook(Book book) async {}
}

void main() {
  final sampleBook = Book(
    id: 'book-dnf-1',
    title: 'The Silent Patient',
    author: 'Alex Michaelides',
    genre: 'Thriller',
    description: 'Psychological thriller',
    status: ReadingStatus.currentlyReading,
    progress: 0.32,
    pages: 336,
    formats: const [BookFormat.ebook],
    addedAt: DateTime(2026, 1, 1),
    coverColors: const [Color(0xFF2B3A55), Color(0xFF111A2B)],
  );

  final dnfData = DnfCompletionData.fromBook(
    sampleBook,
    reason: 'PACING',
    notes: 'Could not connect with the characters',
  );

  testWidgets('DnfCompletionCard renders records (\$1 and \$2) and allows selecting reasons', (tester) async {
    final mockRepo = MockBookRepo([sampleBook]);
    bool backPressed = false;
    bool dnfShelfPressed = false;
    bool undoPressed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: DnfCompletionCard(
              data: dnfData,
              onBackToShelf: () => backPressed = true,
              onDnfShelf: () => dnfShelfPressed = true,
              onUndo: () => undoPressed = true,
            ),
          ),
        ),
      ),
    );

    // Verify main typography and details
    expect(find.text('DID NOT FINISH'), findsOneWidget);
    expect(find.text('The Silent Patient'), findsNWidgets(2)); // in cover and title
    expect(find.text('32%'), findsOneWidget);

    // Verify predefined reason labels ($2) are rendered
    expect(find.text('Pacing Dragged'), findsOneWidget);
    expect(find.text('Not My Vibe'), findsOneWidget);
    expect(find.text('Lost Interest'), findsOneWidget);
    expect(find.text('Writing Style'), findsOneWidget);
    expect(find.text('Right Book, Wrong Time'), findsOneWidget);
    expect(find.text('Disappointing Plot'), findsOneWidget);

    // Initial selected reason is 'PACING' which corresponds to 'Pacing Dragged'
    final initialChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Pacing Dragged'),
    );
    expect(initialChip.selected, isTrue);

    // Tap another chip: 'Not My Vibe' (key 'NOT_MY_VIBE')
    await tester.ensureVisible(find.text('Not My Vibe'));
    await tester.tap(find.text('Not My Vibe'));
    await tester.pumpAndSettle();

    expect(mockRepo.updatedId, 'book-dnf-1');
    expect(mockRepo.updatedStatus, ReadingStatus.dnf);
    expect(mockRepo.updatedReason, 'NOT_MY_VIBE');

    // Tap action buttons
    await tester.ensureVisible(find.text('Back to Shelf'));
    await tester.tap(find.text('Back to Shelf'));
    expect(backPressed, isTrue);

    await tester.ensureVisible(find.text('DNF Shelf'));
    await tester.tap(find.text('DNF Shelf'));
    expect(dnfShelfPressed, isTrue);

    await tester.ensureVisible(find.text('Accidentally retired? Undo DNF'));
    await tester.tap(find.text('Accidentally retired? Undo DNF'));
    expect(undoPressed, isTrue);
  });
}

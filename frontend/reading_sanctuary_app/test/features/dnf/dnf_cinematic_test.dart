import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/dnf/models/dnf_completion_data.dart';
import 'package:reading_sanctuary_app/features/dnf/widgets/burning_book_effect.dart';
import 'package:reading_sanctuary_app/features/dnf/widgets/dnf_completion_card.dart';
import 'package:reading_sanctuary_app/features/dnf/widgets/dnf_ember_particles.dart';
import 'package:reading_sanctuary_app/features/tracker/presentation/screens/reading_tracker_screen.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/book_repository.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';

void main() {
  final sampleBook = Book(
    id: 'test-1',
    title: 'The Great Retirement',
    author: 'Sanctuary Author',
    genre: 'Drama',
    description: 'A story given an intentional farewell.',
    status: ReadingStatus.currentlyReading,
    progress: 0.15,
    pages: 300,
    formats: const [BookFormat.ebook],
    addedAt: DateTime(2026, 1, 1),
    coverColors: const [Color(0xFF2B3A55), Color(0xFF111A2B)],
    dnfDate: DateTime(2026, 11, 13),
    dnfReason: 'PACING',
    dnfNotes: 'Pacing dragged during part two.',
  );

  group('DNF Models and Repository Tests', () {
    test('DnfCompletionData created accurately from Book', () {
      final data = DnfCompletionData.fromBook(sampleBook);

      expect(data.bookId, 'test-1');
      expect(data.title, 'The Great Retirement');
      expect(data.author, 'Sanctuary Author');
      expect(data.currentPage, 45); // (300 * 0.15).round()
      expect(data.totalPages, 300);
      expect(data.readingProgress, 0.15);
      expect(data.dnfReason, 'PACING');
      expect(data.dnfNotes, 'Pacing dragged during part two.');
    });

    test('Book JSON serialization handles DNF fields', () {
      final json = sampleBook.toJson();
      expect(json['status'], 'currentlyReading');
      expect(json['dnfDate'], isNotNull);
      expect(json['dnfReason'], 'PACING');
      expect(json['dnfNotes'], 'Pacing dragged during part two.');

      final reconstructed = Book.fromJson(json);
      expect(reconstructed.id, 'test-1');
      expect(reconstructed.dnfReason, 'PACING');
      expect(reconstructed.dnfNotes, 'Pacing dragged during part two.');
      expect(reconstructed.dnfDate, isNotNull);
    });

    test('Book copyWith supports setting and clearing DNF fields', () {
      final dnfBook = sampleBook.copyWith(
        status: ReadingStatus.dnf,
        dnfDate: DateTime(2026, 11, 13),
        dnfReason: 'NOT_MY_VIBE',
      );
      expect(dnfBook.status, ReadingStatus.dnf);
      expect(dnfBook.dnfReason, 'NOT_MY_VIBE');

      final undoneBook = dnfBook.copyWith(
        status: ReadingStatus.currentlyReading,
        clearDnf: true,
      );
      expect(undoneBook.status, ReadingStatus.currentlyReading);
      expect(undoneBook.dnfDate, isNull);
      expect(undoneBook.dnfReason, isNull);
      expect(undoneBook.dnfNotes, isNull);
    });

    test('MockBookRepository updates status to DNF and handles Undo', () async {
      final repo = MockBookRepository([sampleBook]);
      final retiredDate = DateTime(2026, 11, 13);

      await repo.updateStatus(
        'test-1',
        ReadingStatus.dnf,
        dnfDate: retiredDate,
        dnfReason: 'LOST_INTEREST',
        dnfNotes: 'Moved on to another book',
      );

      var books = await repo.getBooks();
      var b = books.firstWhere((x) => x.id == 'test-1');
      expect(b.status, ReadingStatus.dnf);
      expect(b.dnfReason, 'LOST_INTEREST');
      expect(b.dnfNotes, 'Moved on to another book');

      // Undo operation
      await repo.updateStatus(
        'test-1',
        ReadingStatus.currentlyReading,
      );

      books = await repo.getBooks();
      b = books.firstWhere((x) => x.id == 'test-1');
      expect(b.status, ReadingStatus.currentlyReading);
      expect(b.dnfReason, isNull);
      expect(b.dnfDate, isNull);
    });
  });

  group('DNF Widgets UI Rendering Tests', () {
    testWidgets('BurningBookEffect renders book and aura layers without crashing',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BurningBookEffect(
              book: sampleBook,
              ignitionProgress: 0.5,
              burnProgress: 0.2,
              pulseValue: 0.4,
            ),
          ),
        ),
      );

      expect(find.byType(BurningBookEffect), findsOneWidget);
    });

    testWidgets('DnfEmberParticles paints rising embers', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DnfEmberParticles(intensity: 0.8),
          ),
        ),
      );

      expect(find.byType(DnfEmberParticles), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('DnfCompletionCard displays title, author, stats, and action buttons',
        (tester) async {
      final data = DnfCompletionData.fromBook(sampleBook);
      bool backTapped = false;
      bool dnfShelfTapped = false;
      bool undoTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookRepositoryProvider.overrideWithValue(MockBookRepository([sampleBook])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: DnfCompletionCard(
                data: data,
                onBackToShelf: () => backTapped = true,
                onDnfShelf: () => dnfShelfTapped = true,
                onUndo: () => undoTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('DID NOT FINISH'), findsOneWidget);
      expect(find.text("SOME STORIES AREN'T MEANT TO BE FINISHED."), findsOneWidget);
      expect(find.text('The Great Retirement'), findsOneWidget);
      expect(find.text('Sanctuary Author'), findsOneWidget);
      expect(find.text('15%'), findsOneWidget);
      expect(find.text('PROGRESS STOPPED'), findsOneWidget);

      expect(find.text('Back to Shelf'), findsOneWidget);
      expect(find.text('DNF Shelf'), findsOneWidget);
      expect(find.text('Accidentally retired? Undo DNF'), findsOneWidget);

      await tester.tap(find.text('Back to Shelf'));
      expect(backTapped, isTrue);

      await tester.tap(find.text('DNF Shelf'));
      expect(dnfShelfTapped, isTrue);

      await tester.tap(find.text('Accidentally retired? Undo DNF'));
      expect(undoTapped, isTrue);
    });

    testWidgets('ReadingTrackerScreen displays DNF books and empty state',
        (tester) async {
      final retiredBook = sampleBook.copyWith(
        status: ReadingStatus.dnf,
        progress: 0.12,
        dnfReason: 'LOST_INTEREST',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookRepositoryProvider.overrideWithValue(MockBookRepository([retiredBook])),
          ],
          child: const MaterialApp(
            home: ReadingTrackerScreen(
              title: 'Did Not Finish',
              statusFilter: ReadingStatus.dnf,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Did Not Finish'), findsOneWidget);
      expect(find.text('The Great Retirement'), findsOneWidget);
      expect(find.text('Stopped at 12%'), findsOneWidget);
      expect(find.text('LOST_INTEREST'), findsOneWidget);
    });
  });
}

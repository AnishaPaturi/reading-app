import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/core/network/api_client.dart';
import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/bookshelf/data/models/bookshelf_model.dart';
import 'package:reading_sanctuary_app/features/bookshelf/data/repositories/bookshelf_repository.dart';
import 'package:reading_sanctuary_app/features/bookshelf/data/services/bookshelf_api_service.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/providers/bookshelf_provider.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/bookshelf_section.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/empty_library_state.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/library_header.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/library_statistics.dart';
import 'package:reading_sanctuary_app/features/bookshelf/presentation/widgets/library_toolbar.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/library/library_screen.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/book_repository.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImmediateBookRepository implements BookRepository {
  final List<Book> _books;
  ImmediateBookRepository([List<Book>? books]) : _books = books ?? MockBookRepository.sample();

  @override
  Future<List<Book>> getBooks() async => List.unmodifiable(_books);
  @override
  Future<void> updateStatus(String id, ReadingStatus status) async {}
  @override
  Future<void> updateProgress(String id, double progress) async {}
  @override
  Future<void> addBook(Book book) async {}
}

class FakeBookshelfNotifier extends BookshelfListNotifier {
  FakeBookshelfNotifier(List<BookshelfModel> initial)
      : super(
          repository: BookshelfRepository(
            apiService: BookshelfApiService(
              apiClient: ApiClient(baseUrl: 'http://localhost', tokenProvider: () => null),
            ),
          ),
        ) {
    state = AsyncValue.data(initial);
  }

  @override
  Future<void> loadShelves({bool forceRefresh = false}) async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget({
    Size size = const Size(400, 850),
    List<BookshelfModel> initialShelves = const [],
  }) {
    return ProviderScope(
      overrides: [
        bookRepositoryProvider.overrideWithValue(ImmediateBookRepository()),
        bookshelfListNotifierProvider.overrideWith((ref) => FakeBookshelfNotifier(initialShelves)),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const LibraryScreen(),
        ),
      ),
    );
  }

  testWidgets('Renders Sanctuary Library mobile layout with header, statistics, and toolbar', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(400, 850)));
    await tester.pumpAndSettle();

    // Verify LibraryHeader
    expect(find.byType(LibraryHeader), findsOneWidget);
    expect(find.text('My Library'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    // Verify LibraryStatistics
    expect(find.byType(LibraryStatistics), findsOneWidget);
    expect(find.text('Total Books'), findsOneWidget);
    expect(find.text('Bookshelves'), findsOneWidget);
    expect(find.text('Read This Year'), findsOneWidget);

    // Verify LibraryToolbar
    expect(find.byType(LibraryToolbar), findsOneWidget);
    expect(find.text('My Bookshelves'), findsOneWidget);
    expect(find.text('New Shelf'), findsOneWidget);

    // Verify empty library state when no shelves
    expect(find.byType(EmptyLibraryState), findsOneWidget);
    expect(find.text('Your Book Sanctuary Awaits'), findsOneWidget);
    expect(find.text('Create a Bookshelf'), findsOneWidget);

    // Verify ClayBottomNav on mobile
    expect(find.byType(ClayBottomNav), findsOneWidget);
  });

  testWidgets('Renders custom bookshelves when provided', (tester) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final testShelves = [
      const BookshelfModel(
        id: 'shelf-1',
        name: 'Dark Romance Obsession',
        description: 'Enemies to lovers and morally grey characters',
        themeColor: '#1F1A24',
        accentColor: '#9C27B0',
        icon: 'favorite',
        layoutStyle: 'shelf',
        bookCount: 2,
        bookIds: ['b1', 'b2'],
      ),
      const BookshelfModel(
        id: 'shelf-2',
        name: 'My TBR Sanctuary',
        description: 'Waiting to be explored',
        themeColor: '#2C221E',
        accentColor: '#D4AF37',
        icon: 'book',
        layoutStyle: 'gallery',
        bookCount: 1,
        bookIds: ['b3'],
      ),
    ];

    await tester.pumpWidget(buildTestableWidget(
      size: const Size(400, 1400),
      initialShelves: testShelves,
    ));
    await tester.pumpAndSettle();

    // Verify shelf cards are present
    expect(find.byType(BookshelfCard), findsNWidgets(2));
    expect(find.text('Dark Romance Obsession'), findsOneWidget);
    expect(find.text('My TBR Sanctuary'), findsOneWidget);
    expect(find.text('View shelf'), findsNWidgets(2));
    expect(find.byType(EmptyLibraryState), findsNothing);
  });

  testWidgets('Desktop layout renders ReaderSidebar with My Library active and hides bottom nav', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(1200, 900)));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderSidebar), findsOneWidget);
    expect(find.text('Library'), findsWidgets);
    expect(find.byType(ClayBottomNav), findsNothing);
  });
}

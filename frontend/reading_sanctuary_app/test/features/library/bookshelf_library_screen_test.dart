import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/library/library_screen.dart';
import 'package:reading_sanctuary_app/features/library/widgets/book_preview_sheet.dart';
import 'package:reading_sanctuary_app/features/library/widgets/bookshelf_header.dart';
import 'package:reading_sanctuary_app/features/library/widgets/clay_book_spine.dart';
import 'package:reading_sanctuary_app/features/library/widgets/clay_decorations.dart';
import 'package:reading_sanctuary_app/features/library/widgets/clay_shelf.dart';
import 'package:reading_sanctuary_app/features/library/widgets/library_filter_sheet.dart';

void main() {
  Widget buildTestableWidget({Size size = const Size(400, 850)}) {
    return ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: const LibraryScreen(),
        ),
      ),
    );
  }

  testWidgets('Renders 3D Bookshelf mobile layout with shelves, plants, and search header', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(400, 850)));
    await tester.pumpAndSettle();

    // Verify search header
    expect(find.byType(BookshelfHeader), findsOneWidget);
    expect(find.text('Search books...'), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

    // Verify 3D shelves & spines
    expect(find.byType(ClayShelf), findsWidgets);
    expect(find.byType(ClayBookSpine), findsWidgets);

    // Verify cute clay plants
    expect(find.byType(ClayHangingPlant), findsWidgets);
    expect(find.byType(ClayFlowerPot), findsWidgets);
    expect(find.byType(ClayAloePot), findsWidgets);
    expect(find.byType(ClayBowlSucculent), findsWidgets);

    // Verify sparkles
    expect(find.byType(ClaySparkleStar), findsWidgets);
  });

  testWidgets('Searching filters books on the 3D shelves', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(400, 850)));
    await tester.pumpAndSettle();

    // Type query
    await tester.enterText(find.byType(TextField), 'Atomic');
    await tester.pumpAndSettle();

    // Only Atomic Habits should remain
    expect(find.text('Atomic Habits'), findsOneWidget);
    expect(find.text('The Silent Patient'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('The Silent Patient'), findsOneWidget);
  });

  testWidgets('Tapping a book spine opens BookPreviewSheet', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(400, 850)));
    await tester.pumpAndSettle();

    // Tap first book spine
    final spineFinder = find.byType(ClayBookSpine).first;
    await tester.tap(spineFinder);
    await tester.pumpAndSettle();

    // Verify preview sheet is shown
    expect(find.byType(BookPreviewSheet), findsOneWidget);
    expect(find.text('Reading Progress'), findsOneWidget);
    expect(find.text('Read Now'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('Tapping filter button opens LibraryFilterSheet and allows view mode toggle', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(400, 850)));
    await tester.pumpAndSettle();

    // Tap filter button
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryFilterSheet), findsOneWidget);
    expect(find.text('Filter Library'), findsOneWidget);
    expect(find.text('3D Bookshelf'), findsOneWidget);
    expect(find.text('Cover Grid'), findsOneWidget);

    // Switch to Cover Grid
    await tester.tap(find.text('Cover Grid'));
    await tester.pumpAndSettle();

    // Now in Grid view
    expect(find.byType(ClayShelf), findsNothing);
  });

  testWidgets('Desktop layout renders ReaderSidebar with My Library active', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget(size: const Size(1200, 900)));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderSidebar), findsOneWidget);
    expect(find.text('Library'), findsWidgets);
    expect(find.byType(ClayShelf), findsWidgets);
  });
}

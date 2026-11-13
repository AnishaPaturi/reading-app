import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/library/screens/add_book_screen.dart';

void main() {
  Widget buildTestableWidget() {
    return const ProviderScope(
      child: MaterialApp(
        home: AddBookScreen(),
      ),
    );
  }

  testWidgets('AddBookScreen renders upload-first interface with format badges and how-it-works', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    // Verify header
    expect(find.text('Add New Book'), findsOneWidget);
    expect(find.text("Let's add something wonderful to your library."), findsOneWidget);

    // Verify upload card
    expect(find.text('Upload your book'), findsOneWidget);
    expect(find.text('Select a file from your device'), findsOneWidget);

    // Verify format badges
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('EPUB'), findsOneWidget);
    expect(find.text('MP3'), findsOneWidget);
    expect(find.text('M4B'), findsOneWidget);

    // Verify buttons and sections
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Upload your book file'), findsOneWidget);
    expect(find.text('We automatically identify the book'), findsOneWidget);
    expect(find.text('Review and modify the details'), findsOneWidget);
    expect(find.text('Or enter details manually'), findsOneWidget);
  });

  testWidgets('Tapping "Or enter details manually" switches to manual entry mode', (tester) async {
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    final manualButton = find.text('Or enter details manually');
    await tester.tap(manualButton);
    await tester.pumpAndSettle();

    // Verify manual mode form fields are visible
    expect(find.text('Book Title *'), findsOneWidget);
    expect(find.text('Author *'), findsOneWidget);
    expect(find.text('Genre'), findsOneWidget);
    expect(find.text('Initial Status'), findsOneWidget);
    expect(find.text('Add to Sanctuary'), findsOneWidget);
    expect(find.text('Back to File Upload'), findsOneWidget);
  });
}

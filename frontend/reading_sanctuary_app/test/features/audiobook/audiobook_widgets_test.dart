import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audiobook.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/playback_progress.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/datasources/audiobook_local_datasource.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/audiobook_card.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/audiobook_controls.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/audiobook_empty_state.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/audiobook_progress_bar.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/audiobook_section.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/audiobook_sleep_timer.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/audiobook_speed_selector.dart';

void main() {
  group('Audiobook UI Widget Tests', () {
    testWidgets('AudiobookControls triggers play and skip callbacks', (tester) async {
      bool playToggled = false;
      bool skipForwardTapped = false;
      bool skipBackwardTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudiobookControls(
              isPlaying: false,
              isLoading: false,
              onPlayPause: () => playToggled = true,
              onSkipBackward: () => skipBackwardTapped = true,
              onSkipForward: () => skipForwardTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      expect(playToggled, isTrue);

      await tester.tap(find.byIcon(Icons.forward_30_rounded));
      expect(skipForwardTapped, isTrue);

      await tester.tap(find.byIcon(Icons.replay_10_rounded));
      expect(skipBackwardTapped, isTrue);
    });

    testWidgets('AudiobookProgressBar renders formatted timestamps and remaining time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudiobookProgressBar(
              position: const Duration(minutes: 1, seconds: 30),
              duration: const Duration(minutes: 5, seconds: 0),
              onSeek: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('01:30'), findsOneWidget);
      expect(find.text('-03:30'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('AudiobookSpeedSelector triggers speed selection', (tester) async {
      double selectedSpeed = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudiobookSpeedSelector(
              currentSpeed: 1.0,
              onSpeedSelected: (spd) => selectedSpeed = spd,
            ),
          ),
        ),
      );

      expect(find.text('Playback Speed'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);

      await tester.tap(find.text('1.5x'));
      expect(selectedSpeed, 1.5);
    });

    testWidgets('AudiobookSleepTimerSheet selects sleep duration', (tester) async {
      Duration? selectedDuration;
      bool selectedEndOfChapter = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudiobookSleepTimerSheet(
              remainingTime: null,
              endOfChapter: false,
              onTimerSelected: (dur, {endOfChapter = false}) {
                selectedDuration = dur;
                selectedEndOfChapter = endOfChapter;
              },
            ),
          ),
        ),
      );

      expect(find.text('Sleep Timer'), findsOneWidget);
      expect(find.text('15 minutes'), findsOneWidget);
      expect(find.text('End of current chapter'), findsOneWidget);

      await tester.tap(find.text('15 minutes'));
      expect(selectedDuration, const Duration(minutes: 15));
      expect(selectedEndOfChapter, isFalse);
    });

    testWidgets('AudiobookEmptyState renders sanctuary message and import button', (tester) async {
      bool importTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudiobookEmptyState(
              onImport: () => importTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('Your audiobook sanctuary is waiting.'), findsOneWidget);
      expect(find.textContaining('Import your first audiobook'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Import Audiobook'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Import Audiobook'));
      expect(importTriggered, isTrue);
    });

    testWidgets('AudiobookCard renders title, author, and progress percentage', (tester) async {
      bool tapped = false;
      final book = Audiobook(
        id: 'book-1',
        title: 'The Fine Print',
        author: 'Lauren Asher',
        totalDurationMs: 36000000, // 10 hours
        totalTracks: 10,
        status: AudiobookStatus.current,
        dateAdded: DateTime(2026, 1, 1),
      );
      final progress = PlaybackProgress(
        audiobookId: 'book-1',
        trackIndex: 0,
        positionMs: 14400000, // 4 hours = 40%
        totalDurationMs: 36000000,
        playbackSpeed: 1.0,
        lastListenedAt: DateTime(2026, 1, 2),
        completed: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AudiobookCard(
                audiobook: book,
                progress: progress,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('The Fine Print'), findsWidgets);
      expect(find.text('Lauren Asher'), findsWidgets);
      expect(find.text('40% completed'), findsOneWidget);

      await tester.tap(find.text('The Fine Print').last);
      expect(tapped, isTrue);
    });

    testWidgets('AudiobookSection renders title, count badge, and cards', (tester) async {
      final book1 = Audiobook(
        id: 'book-1',
        title: 'Book One',
        author: 'Author A',
        totalDurationMs: 10000,
        totalTracks: 1,
        status: AudiobookStatus.current,
        dateAdded: DateTime.now(),
      );
      final book2 = Audiobook(
        id: 'book-2',
        title: 'Book Two',
        author: 'Author B',
        totalDurationMs: 20000,
        totalTracks: 2,
        status: AudiobookStatus.current,
        dateAdded: DateTime.now(),
      );

      final ds = AudiobookLocalDatasource();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AudiobookSection(
                title: 'Current',
                audiobooks: [book1, book2],
                localDb: ds,
                onBookTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Current'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Book One'), findsWidgets);
      expect(find.text('Book Two'), findsWidgets);
    });
  });
}

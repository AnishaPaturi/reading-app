import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/audiobook_controls.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/audiobook_progress_bar.dart';
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

    testWidgets('AudiobookProgressBar renders formatted timestamps', (tester) async {
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
  });
}

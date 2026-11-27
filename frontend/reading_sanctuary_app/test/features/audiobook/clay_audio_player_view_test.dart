import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/presentation/widgets/clay_audio_player_view.dart';

void main() {
  group('ClayAudioPlayerView Widget Tests', () {
    testWidgets('renders all Clay Audio Player components accurately matching design', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool backTapped = false;
      bool optionsTapped = false;
      bool playPauseTapped = false;
      bool rewindTapped = false;
      bool forwardTapped = false;
      bool chaptersTapped = false;
      bool sleepTimerTapped = false;
      bool bookmarkTapped = false;
      bool speedTapped = false;
      bool silenceTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayAudioPlayerView(
              title: 'The Silent Patient',
              author: 'Alex Michaelides',
              chapterTitle: 'Chapter 08',
              position: const Duration(hours: 1, minutes: 25, seconds: 30),
              duration: const Duration(hours: 8, minutes: 45, seconds: 20),
              isPlaying: false,
              playbackSpeed: 1.25,
              silenceSkipping: true,
              onBack: () => backTapped = true,
              onOptions: () => optionsTapped = true,
              onPlayPause: () => playPauseTapped = true,
              onRewind15: () => rewindTapped = true,
              onForward30: () => forwardTapped = true,
              onSeek: (_) {},
              onChapters: () => chaptersTapped = true,
              onSleepTimer: () => sleepTimerTapped = true,
              onBookmark: () => bookmarkTapped = true,
              onSpeed: () => speedTapped = true,
              onToggleSilence: () => silenceTapped = true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // 1. Top bar
      expect(find.text('NOW PLAYING'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

      // 2. Book Title, Author, Chapter
      expect(find.text('The Silent Patient'), findsOneWidget);
      expect(find.text('Alex Michaelides'), findsOneWidget);
      expect(find.text('Chapter 08'), findsOneWidget);

      // 3. Timestamps
      expect(find.text('01:25:30'), findsOneWidget);
      expect(find.text('08:45:20'), findsOneWidget);

      // 4. Transport Controls
      expect(find.text('-15s'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('+30s'), findsOneWidget);

      // 5. Action Pills
      expect(find.text('Chapters'), findsOneWidget);
      expect(find.text('Sleep Timer'), findsOneWidget);
      expect(find.text('Bookmark'), findsOneWidget);

      // 6. Bottom Floating Speed & Silence Card
      expect(find.text('1.25x'), findsOneWidget);
      expect(find.text('Skip silence: ON'), findsOneWidget);

      // 7. Verify Interactions
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      expect(backTapped, isTrue);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      expect(optionsTapped, isTrue);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      expect(playPauseTapped, isTrue);

      await tester.tap(find.text('-15s'));
      expect(rewindTapped, isTrue);

      await tester.tap(find.text('+30s'));
      expect(forwardTapped, isTrue);

      await tester.tap(find.text('Chapters'));
      expect(chaptersTapped, isTrue);

      await tester.tap(find.text('Sleep Timer'));
      expect(sleepTimerTapped, isTrue);

      await tester.tap(find.text('Bookmark'));
      expect(bookmarkTapped, isTrue);

      await tester.tap(find.text('1.25x'));
      expect(speedTapped, isTrue);

      await tester.tap(find.text('Skip silence: ON'));
      expect(silenceTapped, isTrue);
    });

    testWidgets('ClayAudioPlayerView renders pause icon when isPlaying is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClayAudioPlayerView(
              title: 'The Silent Patient',
              chapterTitle: 'Chapter 08',
              position: Duration.zero,
              duration: const Duration(minutes: 10),
              isPlaying: true,
              playbackSpeed: 1.0,
              silenceSkipping: false,
              onBack: () {},
              onOptions: () {},
              onPlayPause: () {},
              onRewind15: () {},
              onForward30: () {},
              onSeek: (_) {},
              onChapters: () {},
              onSleepTimer: () {},
              onBookmark: () {},
              onSpeed: () {},
              onToggleSilence: () {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Skip silence: OFF'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
    });
  });
}

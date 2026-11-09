import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/text_to_speech/data/models/tts_document.dart';
import 'package:reading_sanctuary_app/features/text_to_speech/presentation/widgets/tts_controls.dart';
import 'package:reading_sanctuary_app/features/text_to_speech/presentation/widgets/tts_text_display.dart';

void main() {
  group('TTS Models Tests', () {
    test('TtsDocument parses from JSON correctly', () {
      final json = {
        'bookId': 'book-1',
        'bookFileId': 'file-1',
        'format': 'EPUB',
        'chapter': 2,
        'title': 'Chapter Two',
        'chunks': [
          {'index': 0, 'text': 'Hello world paragraph.'},
          {'index': 1, 'text': 'Next paragraph.'},
        ],
        'hasNextChapter': true,
      };

      final doc = TtsDocument.fromJson(json);
      expect(doc.bookId, 'book-1');
      expect(doc.format, 'EPUB');
      expect(doc.chapter, 2);
      expect(doc.chunks.length, 2);
      expect(doc.chunks.first.text, 'Hello world paragraph.');
      expect(doc.hasNextChapter, isTrue);
    });

    test('TtsPosition roundtrip from/to JSON', () {
      final json = {
        'chapterIndex': 3,
        'chunkIndex': 1,
        'characterOffset': 45,
        'progressPercentage': 35.5,
        'updatedAt': '2026-11-09T07:15:00.000Z',
      };

      final pos = TtsPosition.fromJson(json);
      expect(pos.chapterIndex, 3);
      expect(pos.chunkIndex, 1);
      expect(pos.characterOffset, 45);
      expect(pos.progressPercentage, 35.5);

      final out = pos.toJson();
      expect(out['chapterIndex'], 3);
      expect(out['chunkIndex'], 1);
      expect(out['characterOffset'], 45);
    });
  });

  group('TTS UI Widget Tests', () {
    testWidgets('TtsControls triggers play, stop and chunk callbacks', (tester) async {
      bool playToggled = false;
      bool stopped = false;
      bool nextTapped = false;
      bool prevTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TtsControls(
              isSpeaking: false,
              isPaused: false,
              isLoading: false,
              onPlayPause: () => playToggled = true,
              onStop: () => stopped = true,
              onNextChunk: () => nextTapped = true,
              onPreviousChunk: () => prevTapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      expect(playToggled, isTrue);

      await tester.tap(find.byIcon(Icons.stop_rounded));
      expect(stopped, isTrue);

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      expect(nextTapped, isTrue);

      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      expect(prevTapped, isTrue);
    });

    testWidgets('TtsTextDisplay renders text and chapter information', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TtsTextDisplay(
              text: 'The opening words of the book.',
              spokenWord: 'words',
              currentChunk: 0,
              totalChunks: 5,
              currentChapter: 1,
            ),
          ),
        ),
      );

      expect(find.text('Chapter 1'), findsOneWidget);
      expect(find.text('Paragraph 1 of 5'), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
    });
  });
}

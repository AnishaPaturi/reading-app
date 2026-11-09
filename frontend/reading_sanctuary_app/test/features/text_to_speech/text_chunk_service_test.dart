import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/text_to_speech/domain/services/text_chunk_service.dart';

void main() {
  group('TextChunkService Tests', () {
    late TextChunkService service;

    setUp(() {
      service = TextChunkService();
    });

    test('splitText divides text by paragraphs', () {
      final sample = 'First paragraph.\n\nSecond paragraph.\n\nThird paragraph.';
      final chunks = service.splitText(sample);

      expect(chunks.length, 1);
      expect(chunks.first, contains('First paragraph.'));
      expect(chunks.first, contains('Second paragraph.'));
    });

    test('splitText breaks large paragraphs exceeding maxChunkLength', () {
      final largeParagraph = 'A' * 3000;
      final chunks = service.splitText(largeParagraph);

      expect(chunks.length, greaterThan(1));
      expect(chunks.first.length, lessThanOrEqualTo(TextChunkService.maxChunkLength));
    });

    test('splitText returns empty list for blank text', () {
      expect(service.splitText('   \n\n   '), isEmpty);
      expect(service.splitText(''), isEmpty);
    });
  });
}

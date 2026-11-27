import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/book_discovery/services/file_signature_validator.dart';

void main() {
  group('FileSignatureValidator', () {
    test('rejects empty files (0 bytes)', () {
      final error = FileSignatureValidator.validateSignature('pdf', Uint8List(0), 0);
      expect(error, contains('0 bytes'));
    });

    test('validates valid PDF magic bytes (%PDF)', () {
      final header = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
      final error = FileSignatureValidator.validateSignature('pdf', header, 1024);
      expect(error, isNull);
    });

    test('rejects fake PDF with non-PDF signature', () {
      final header = Uint8List.fromList([0x4D, 0x5A, 0x00, 0x00]); // EXE signature
      final error = FileSignatureValidator.validateSignature('pdf', header, 1024);
      expect(error, contains('does not match PDF format'));
    });

    test('validates valid EPUB and DOCX PK ZIP signature', () {
      final header = Uint8List.fromList([0x50, 0x4B, 0x03, 0x04]);
      expect(FileSignatureValidator.validateSignature('epub', header, 5000), isNull);
      expect(FileSignatureValidator.validateSignature('docx', header, 8000), isNull);
    });

    test('validates MP3 ID3 and MPEG sync signatures', () {
      final id3Header = Uint8List.fromList([0x49, 0x44, 0x33, 0x03, 0x00]);
      expect(FileSignatureValidator.validateSignature('mp3', id3Header, 10000), isNull);

      final mpegHeader = Uint8List.fromList([0xFF, 0xFB, 0x90, 0x64]);
      expect(FileSignatureValidator.validateSignature('mp3', mpegHeader, 10000), isNull);
    });

    test('validates M4B and M4A ftyp container signature', () {
      final m4bHeader = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, // ...ftyp
        0x4D, 0x34, 0x41, 0x20,
      ]);
      expect(FileSignatureValidator.validateSignature('m4b', m4bHeader, 200000), isNull);
      expect(FileSignatureValidator.validateSignature('m4a', m4bHeader, 200000), isNull);
    });

    test('rejects unsupported file formats', () {
      final header = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
      expect(FileSignatureValidator.validateSignature('iso', header, 1000), contains('Unsupported format'));
      expect(FileSignatureValidator.validateSignature('exe', header, 1000), contains('Unsupported format'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/library/data/models/book_metadata.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';

void main() {
  group('BookFile and BookFileFormat', () {
    test('BookFileFormat correctly provides labels and audio flags', () {
      expect(BookFileFormat.pdf.label, 'PDF');
      expect(BookFileFormat.epub.label, 'EPUB');
      expect(BookFileFormat.mp3.label, 'MP3');
      expect(BookFileFormat.m4b.label, 'M4B');

      expect(BookFileFormat.pdf.isAudio, isFalse);
      expect(BookFileFormat.epub.isAudio, isFalse);
      expect(BookFileFormat.mp3.isAudio, isTrue);
      expect(BookFileFormat.m4b.isAudio, isTrue);
    });

    test('BookFile toJson and fromJson serialization works accurately', () {
      final file = BookFile(
        id: 'file-123',
        format: BookFileFormat.epub,
        fileName: 'cruel_prince.epub',
        fileSize: 204800,
        storageKey: 'books/uuid.epub',
        durationSeconds: null,
      );

      final json = file.toJson();
      expect(json['id'], 'file-123');
      expect(json['format'], 'epub');
      expect(json['fileName'], 'cruel_prince.epub');
      expect(json['fileSize'], 204800);
      expect(json['storageKey'], 'books/uuid.epub');

      final restored = BookFile.fromJson(json);
      expect(restored.id, 'file-123');
      expect(restored.format, BookFileFormat.epub);
      expect(restored.fileName, 'cruel_prince.epub');
      expect(restored.fileSize, 204800);
      expect(restored.storageKey, 'books/uuid.epub');
    });

    test('Book handles multiple attached files and maintains backward compatibility', () {
      final file1 = BookFile(
        id: 'f1',
        format: BookFileFormat.epub,
        fileName: 'book.epub',
        fileSize: 1000,
      );
      final file2 = BookFile(
        id: 'f2',
        format: BookFileFormat.mp3,
        fileName: 'book.mp3',
        fileSize: 50000,
        durationSeconds: 3600,
      );

      final book = Book(
        id: 'book-1',
        title: 'The Cruel Prince',
        author: 'Holly Black',
        genre: 'Fantasy',
        description: 'Faerie fantasy',
        status: ReadingStatus.currentlyReading,
        progress: 0.35,
        pages: 370,
        formats: const [BookFormat.ebook, BookFormat.audiobook],
        files: [file1, file2],
        addedAt: DateTime(2026, 11, 1),
        coverColors: const [Color(0xFF9482E6), Color(0xFF6550C7)],
      );

      expect(book.files.length, 2);
      expect(book.files[0].format, BookFileFormat.epub);
      expect(book.files[1].format, BookFileFormat.mp3);

      final json = book.toJson();
      expect(json['files'], isA<List>());
      expect((json['files'] as List).length, 2);

      final parsed = Book.fromJson(json);
      expect(parsed.files.length, 2);
      expect(parsed.files[0].fileName, 'book.epub');
      expect(parsed.files[1].durationSeconds, 3600);
    });
  });

  group('BookMetadata', () {
    test('BookMetadata serializes and deserializes accurately', () {
      const metadata = BookMetadata(
        uploadId: 'upload-abc-123',
        fileName: 'sample.pdf',
        format: 'PDF',
        title: 'Clean Architecture',
        author: 'Robert C. Martin',
        genre: 'Technology',
        pages: 350,
        language: 'en',
      );

      final json = metadata.toJson();
      expect(json['uploadId'], 'upload-abc-123');
      expect(json['title'], 'Clean Architecture');

      final fromJson = BookMetadata.fromJson(json);
      expect(fromJson.uploadId, 'upload-abc-123');
      expect(fromJson.author, 'Robert C. Martin');
      expect(fromJson.pages, 350);
    });
  });
}

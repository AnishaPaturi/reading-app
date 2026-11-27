import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/datasources/audiobook_local_datasource.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audiobook.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_track.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_scanner_service.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_import_service.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_duplicate_detection_service.dart';

void main() {
  late Directory tempDir;
  late AudiobookLocalDatasource datasource;
  late AudiobookDuplicateDetectionService duplicateService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rs_dup_test_');
    datasource = AudiobookLocalDatasource(customDirectoryPath: tempDir.path);
    await datasource.init();
    duplicateService = AudiobookDuplicateDetectionService(dataSource: datasource);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  DiscoveredBook makeDiscoveredBook({
    String id = 'disc-1',
    String title = 'The Silent Patient',
    String author = 'Alex Michaelides',
    List<AudioTrack>? tracks,
    int totalDurationMs = 120000,
  }) {
    return DiscoveredBook(
      id: id,
      title: title,
      author: author,
      tracks: tracks ??
          [
            AudioTrack(
              id: 't-1',
              audiobookId: id,
              filePath: '${tempDir.path}/audio/track1.mp3',
              fileName: 'track1.mp3',
              trackOrder: 1,
              durationMs: 60000,
              format: 'MP3',
              fileSizeBytes: 1024,
            ),
          ],
      totalDurationMs: totalDurationMs,
    );
  }

  Audiobook makeExistingAudiobook({
    String id = 'existing-1',
    String title = 'The Silent Patient',
    String author = 'Alex Michaelides',
  }) {
    return Audiobook(
      id: id,
      title: title,
      author: author,
      totalDurationMs: 120000,
      totalTracks: 1,
      status: AudiobookStatus.notStarted,
      dateAdded: DateTime.now(),
    );
  }

  group('Milestone 2D.2 — Duplicate Detection Rules', () {
    test('Empty library returns DuplicateStatus.none for all books', () async {
      final book = makeDiscoveredBook();
      final entries = await duplicateService.checkDuplicates(discoveredBooks: [book]);

      expect(entries.length, 1);
      expect(entries.first.result.status, DuplicateStatus.none);
      expect(entries.first.result.isDuplicate, isFalse);
    });

    test('Exact normalized path match reports exactFileMatch', () async {
      final existingBook = makeExistingAudiobook();
      final track = AudioTrack(
        id: 'ex-t1',
        audiobookId: existingBook.id,
        filePath: '${tempDir.path}/books/silent_patient/01.mp3',
        fileName: '01.mp3',
        trackOrder: 1,
        durationMs: 60000,
        format: 'MP3',
      );
      await datasource.saveAudiobook(existingBook, [track]);

      final incomingBook = makeDiscoveredBook(
        title: 'Completely Different Title',
        author: 'Unknown Author',
        tracks: [
          AudioTrack(
            id: 'in-t1',
            audiobookId: 'disc-1',
            filePath: '${tempDir.path}/books/silent_patient/01.mp3',
            fileName: '01.mp3',
            trackOrder: 1,
            durationMs: 60000,
            format: 'MP3',
          ),
        ],
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      expect(entries.length, 1);
      final res = entries.first.result;
      expect(res.status, DuplicateStatus.exactFileMatch);
      expect(res.isExactMatch, isTrue);
      expect(res.existingBookId, existingBook.id);
      expect(res.existingBookTitle, existingBook.title);
      expect(res.matchingFilePaths, contains(track.filePath));
    });

    test('Windows separator differences (/ vs \\) correctly match paths', () async {
      final existingBook = makeExistingAudiobook();
      final track = AudioTrack(
        id: 'ex-t1',
        audiobookId: existingBook.id,
        filePath: 'C:/Audiobooks/Dune/01.mp3',
        fileName: '01.mp3',
        trackOrder: 1,
        durationMs: 60000,
        format: 'MP3',
      );
      await datasource.saveAudiobook(existingBook, [track]);

      final incomingBook = makeDiscoveredBook(
        tracks: const [
          AudioTrack(
            id: 'in-t1',
            audiobookId: 'disc-1',
            filePath: r'C:\Audiobooks\Dune\01.mp3',
            fileName: '01.mp3',
            trackOrder: 1,
            durationMs: 60000,
            format: 'MP3',
          ),
        ],
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      expect(entries.first.result.status, DuplicateStatus.exactFileMatch);
    });

    test('Case differences on Windows match paths', () async {
      final existingBook = makeExistingAudiobook();
      final track = AudioTrack(
        id: 'ex-t1',
        audiobookId: existingBook.id,
        filePath: 'c:/audiobooks/hobbit/01.mp3',
        fileName: '01.mp3',
        trackOrder: 1,
        durationMs: 60000,
        format: 'MP3',
      );
      await datasource.saveAudiobook(existingBook, [track]);

      final incomingBook = makeDiscoveredBook(
        tracks: const [
          AudioTrack(
            id: 'in-t1',
            audiobookId: 'disc-1',
            filePath: 'C:/AUDIOBOOKS/HOBBIT/01.MP3',
            fileName: '01.MP3',
            trackOrder: 1,
            durationMs: 60000,
            format: 'MP3',
          ),
        ],
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      if (Platform.isWindows) {
        expect(entries.first.result.status, DuplicateStatus.exactFileMatch);
      }
    });

    test('Different path with same file size is NOT treated as an exact duplicate', () async {
      final existingBook = makeExistingAudiobook();
      final track = AudioTrack(
        id: 'ex-t1',
        audiobookId: existingBook.id,
        filePath: '${tempDir.path}/library/01.mp3',
        fileName: '01.mp3',
        trackOrder: 1,
        durationMs: 60000,
        format: 'MP3',
        fileSizeBytes: 5000000,
      );
      await datasource.saveAudiobook(existingBook, [track]);

      final incomingBook = makeDiscoveredBook(
        title: 'Different Story',
        author: 'Different Writer',
        tracks: [
          AudioTrack(
            id: 'in-t1',
            audiobookId: 'disc-1',
            filePath: '${tempDir.path}/downloads/other_track.mp3',
            fileName: 'other_track.mp3',
            trackOrder: 1,
            durationMs: 60000,
            format: 'MP3',
            fileSizeBytes: 5000000, // Same size, different path & different metadata
          ),
        ],
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      expect(entries.first.result.status, DuplicateStatus.none);
      expect(entries.first.result.isDuplicate, isFalse);
    });

    test('Same title AND author matches as possibleBookMatch', () async {
      final existingBook = makeExistingAudiobook(
        title: 'The Silent Patient',
        author: 'Alex Michaelides',
      );
      await datasource.saveAudiobook(existingBook, []);

      final incomingBook = makeDiscoveredBook(
        title: 'The Silent Patient',
        author: 'Alex Michaelides',
        tracks: [
          AudioTrack(
            id: 'in-t1',
            audiobookId: 'disc-1',
            filePath: '${tempDir.path}/new_downloads/01.mp3',
            fileName: '01.mp3',
            trackOrder: 1,
            durationMs: 60000,
            format: 'MP3',
          ),
        ],
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      final res = entries.first.result;
      expect(res.status, DuplicateStatus.possibleBookMatch);
      expect(res.isPossibleMatch, isTrue);
      expect(res.existingBookId, existingBook.id);
      expect(res.existingBookTitle, 'The Silent Patient');
    });

    test('Different title casing and whitespace matches as possibleBookMatch', () async {
      final existingBook = makeExistingAudiobook(
        title: 'The Silent Patient',
        author: 'Alex Michaelides',
      );
      await datasource.saveAudiobook(existingBook, []);

      final incomingBook = makeDiscoveredBook(
        title: '  the   silent  patient  ',
        author: 'alex michaelides',
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      expect(entries.first.result.status, DuplicateStatus.possibleBookMatch);
    });

    test('Same title but different author is NOT a duplicate', () async {
      final existingBook = makeExistingAudiobook(
        title: 'Great Expectations',
        author: 'Charles Dickens',
      );
      await datasource.saveAudiobook(existingBook, []);

      final incomingBook = makeDiscoveredBook(
        title: 'Great Expectations',
        author: 'Kathy Acker',
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      expect(entries.first.result.status, DuplicateStatus.none);
    });

    test('Same title with missing/empty author is NOT a duplicate', () async {
      final existingBook = makeExistingAudiobook(
        title: 'The Silent Patient',
        author: 'Alex Michaelides',
      );
      await datasource.saveAudiobook(existingBook, []);

      final incomingBook = makeDiscoveredBook(
        title: 'The Silent Patient',
        author: 'Unknown Author',
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      expect(entries.first.result.status, DuplicateStatus.none);
    });

    test('Same author with different title is NOT a duplicate', () async {
      final existingBook = makeExistingAudiobook(
        title: 'The Silent Patient',
        author: 'Alex Michaelides',
      );
      await datasource.saveAudiobook(existingBook, []);

      final incomingBook = makeDiscoveredBook(
        title: 'The Maidens',
        author: 'Alex Michaelides',
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      expect(entries.first.result.status, DuplicateStatus.none);
    });

    test('Different edition title is NOT a duplicate', () async {
      final existingBook = makeExistingAudiobook(
        title: 'The Silent Patient',
        author: 'Alex Michaelides',
      );
      await datasource.saveAudiobook(existingBook, []);

      final incomingBook = makeDiscoveredBook(
        title: "The Silent Patient: Collector's Edition",
        author: 'Alex Michaelides',
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incomingBook]);
      expect(entries.first.result.status, DuplicateStatus.none);
    });

    test('Multiple existing books returns the correct matching book', () async {
      final book1 = makeExistingAudiobook(id: 'b1', title: 'Dune', author: 'Frank Herbert');
      final book2 = makeExistingAudiobook(id: 'b2', title: '1984', author: 'George Orwell');
      final book3 = makeExistingAudiobook(id: 'b3', title: 'The Hobbit', author: 'J.R.R. Tolkien');

      await datasource.saveAudiobook(book1, []);
      await datasource.saveAudiobook(book2, []);
      await datasource.saveAudiobook(book3, []);

      final incoming = makeDiscoveredBook(title: '1984', author: 'George Orwell');
      final entries = await duplicateService.checkDuplicates(discoveredBooks: [incoming]);

      expect(entries.first.result.status, DuplicateStatus.possibleBookMatch);
      expect(entries.first.result.existingBookId, 'b2');
      expect(entries.first.result.existingBookTitle, '1984');
    });

    test('Inaccessible or empty source file path does not crash detection', () async {
      final book = makeDiscoveredBook(
        tracks: const [
          AudioTrack(
            id: 't-empty',
            audiobookId: 'disc-1',
            filePath: '',
            fileName: 'unknown.mp3',
            trackOrder: 1,
            durationMs: 0,
            format: 'MP3',
          ),
          AudioTrack(
            id: 't-ghost',
            audiobookId: 'disc-1',
            filePath: '/non_existent/path/never_created.mp3',
            fileName: 'never_created.mp3',
            trackOrder: 2,
            durationMs: 0,
            format: 'MP3',
          ),
        ],
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [book]);
      expect(entries.length, 1);
      expect(entries.first.result.status, DuplicateStatus.none);
    });

    test('Multiple discovered books yield independent duplicate results', () async {
      final existing = makeExistingAudiobook(
        id: 'ex-1',
        title: 'Project Hail Mary',
        author: 'Andy Weir',
      );
      final track = AudioTrack(
        id: 't-ex',
        audiobookId: existing.id,
        filePath: '${tempDir.path}/phm/01.mp3',
        fileName: '01.mp3',
        trackOrder: 1,
        durationMs: 100000,
        format: 'MP3',
      );
      await datasource.saveAudiobook(existing, [track]);

      // Book 1: Exact file match
      final disc1 = makeDiscoveredBook(
        id: 'd1',
        title: 'Hail Mary',
        author: 'Someone Else',
        tracks: [track],
      );

      // Book 2: Possible book match
      final disc2 = makeDiscoveredBook(
        id: 'd2',
        title: 'Project Hail Mary',
        author: 'Andy Weir',
        tracks: [
          AudioTrack(
            id: 't-d2',
            audiobookId: 'd2',
            filePath: '${tempDir.path}/other/different_path.mp3',
            fileName: 'different_path.mp3',
            trackOrder: 1,
            durationMs: 100000,
            format: 'MP3',
          ),
        ],
      );

      // Book 3: No duplicate
      final disc3 = makeDiscoveredBook(
        id: 'd3',
        title: 'Neuromancer',
        author: 'William Gibson',
        tracks: [
          AudioTrack(
            id: 't-d3',
            audiobookId: 'd3',
            filePath: '${tempDir.path}/neuro/01.mp3',
            fileName: '01.mp3',
            trackOrder: 1,
            durationMs: 100000,
            format: 'MP3',
          ),
        ],
      );

      final entries = await duplicateService.checkDuplicates(discoveredBooks: [disc1, disc2, disc3]);
      expect(entries.length, 3);
      expect(entries[0].result.status, DuplicateStatus.exactFileMatch);
      expect(entries[1].result.status, DuplicateStatus.possibleBookMatch);
      expect(entries[2].result.status, DuplicateStatus.none);
    });
  });

  group('Milestone 2D.2 — Import Actions & Persistence Commit', () {
    late AudiobookImportService importService;

    setUp(() {
      importService = AudiobookImportService(
        localDatasource: datasource,
      );
    });

    test('Skip duplicate leaves existing library unchanged', () async {
      final existing = makeExistingAudiobook(id: 'ex-1', title: 'Dune', author: 'Frank Herbert');
      await datasource.saveAudiobook(existing, []);

      final incoming = makeDiscoveredBook(title: 'Dune', author: 'Frank Herbert');
      final entry = AudiobookDuplicateEntry(
        book: incoming,
        result: const DuplicateCheckResult(
          status: DuplicateStatus.possibleBookMatch,
          existingBookId: 'ex-1',
          existingBookTitle: 'Dune',
        ),
        action: DuplicateAction.skip,
      );

      final result = await importService.commitImportedBooks(entries: [entry]);
      expect(result.hasErrors, isFalse);
      expect(result.skippedBooks.length, 1);
      expect(result.importedBooks.isEmpty, isTrue);
      expect(result.replacedBooks.isEmpty, isTrue);

      // Verify library has only the original book
      final all = datasource.getAllAudiobooks();
      expect(all.length, 1);
      expect(all.first.id, 'ex-1');
    });

    test('Import Anyway creates new separate audiobook and tracks', () async {
      final existing = makeExistingAudiobook(id: 'ex-1', title: 'Dune', author: 'Frank Herbert');
      await datasource.saveAudiobook(existing, []);

      final incoming = makeDiscoveredBook(title: 'Dune', author: 'Frank Herbert');
      final entry = AudiobookDuplicateEntry(
        book: incoming,
        result: const DuplicateCheckResult(
          status: DuplicateStatus.possibleBookMatch,
          existingBookId: 'ex-1',
          existingBookTitle: 'Dune',
        ),
        action: DuplicateAction.importAnyway,
      );

      final result = await importService.commitImportedBooks(entries: [entry]);
      expect(result.hasErrors, isFalse);
      expect(result.importedBooks.length, 1);

      final importedBook = result.importedBooks.first;
      expect(importedBook.id, isNot('ex-1')); // Must have a fresh unique ID
      expect(importedBook.title, 'Dune');

      // Library now contains both
      final all = datasource.getAllAudiobooks();
      expect(all.length, 2);
      expect(all.map((b) => b.id).toSet(), containsAll({'ex-1', importedBook.id}));

      // Verify tracks reference the new audiobook ID
      final newTracks = datasource.getTracksForBook(importedBook.id);
      expect(newTracks.length, 1);
      expect(newTracks.first.audiobookId, importedBook.id);
    });

    test('Import non-duplicate executes standard import', () async {
      final incoming = makeDiscoveredBook(title: 'Brave New World', author: 'Aldous Huxley');
      final entry = AudiobookDuplicateEntry(
        book: incoming,
        result: const DuplicateCheckResult(status: DuplicateStatus.none),
      );

      final result = await importService.commitImportedBooks(entries: [entry]);
      expect(result.hasErrors, isFalse);
      expect(result.importedBooks.length, 1);
      expect(result.importedBooks.first.title, 'Brave New World');

      final all = datasource.getAllAudiobooks();
      expect(all.length, 1);
      expect(all.first.title, 'Brave New World');
    });

    test('Replace confirmed updates existing audiobook consistently and safely', () async {
      final existing = makeExistingAudiobook(
        id: 'ex-1',
        title: 'Old Title',
        author: 'Old Author',
      );
      const oldTrack = AudioTrack(
        id: 'old-t',
        audiobookId: 'ex-1',
        filePath: '/old/path.mp3',
        fileName: 'path.mp3',
        trackOrder: 1,
        durationMs: 50000,
        format: 'MP3',
      );
      await datasource.saveAudiobook(existing, [oldTrack]);

      final incoming = makeDiscoveredBook(
        title: 'New Improved Title',
        author: 'Correct Author',
        tracks: const [
          AudioTrack(
            id: 'new-t1',
            audiobookId: 'incoming',
            filePath: '/new/01.mp3',
            fileName: '01.mp3',
            trackOrder: 1,
            durationMs: 80000,
            format: 'MP3',
          ),
          AudioTrack(
            id: 'new-t2',
            audiobookId: 'incoming',
            filePath: '/new/02.mp3',
            fileName: '02.mp3',
            trackOrder: 2,
            durationMs: 90000,
            format: 'MP3',
          ),
        ],
      );

      final entry = AudiobookDuplicateEntry(
        book: incoming,
        result: const DuplicateCheckResult(
          status: DuplicateStatus.possibleBookMatch,
          existingBookId: 'ex-1',
          existingBookTitle: 'Old Title',
        ),
        action: DuplicateAction.replace,
      );

      final result = await importService.commitImportedBooks(entries: [entry]);
      expect(result.hasErrors, isFalse);
      expect(result.replacedBooks.length, 1);

      // Verify existing book ID was preserved
      final updatedBook = datasource.getAudiobook('ex-1');
      expect(updatedBook, isNotNull);
      expect(updatedBook!.id, 'ex-1');
      expect(updatedBook.title, 'New Improved Title');
      expect(updatedBook.author, 'Correct Author');

      // Verify tracks updated and reference ex-1
      final tracks = datasource.getTracksForBook('ex-1');
      expect(tracks.length, 2);
      expect(tracks[0].audiobookId, 'ex-1');
      expect(tracks[1].audiobookId, 'ex-1');
    });

    test('Replace with ambiguous or missing match is blocked', () async {
      final incoming = makeDiscoveredBook(title: 'Some Book', author: 'Author');
      final entry = AudiobookDuplicateEntry(
        book: incoming,
        result: const DuplicateCheckResult(
          status: DuplicateStatus.possibleBookMatch,
          existingBookId: null, // Ambiguous / missing ID
        ),
        action: DuplicateAction.replace,
      );

      final result = await importService.commitImportedBooks(entries: [entry]);
      expect(result.hasErrors, isTrue);
      expect(result.replacedBooks.isEmpty, isTrue);
      expect(result.errors.first, contains('no unambiguous existing audiobook match'));
    });

    test('Missing duplicate decision rejects commit with an explicit error', () async {
      final incoming = makeDiscoveredBook(title: 'Dune', author: 'Frank Herbert');
      final entry = AudiobookDuplicateEntry(
        book: incoming,
        result: const DuplicateCheckResult(
          status: DuplicateStatus.possibleBookMatch,
          existingBookId: 'ex-1',
        ),
        action: null, // Unresolved decision!
      );

      final result = await importService.commitImportedBooks(entries: [entry]);
      expect(result.hasErrors, isTrue);
      expect(result.successfulCount, 0);
      expect(result.errors.first, contains('Missing duplicate decision'));
    });

    test('Partial failure allows other valid books to still be processed', () async {
      final book1 = makeDiscoveredBook(
        id: 'b1',
        title: 'Invalid Replace Book',
        author: 'Author 1',
      );
      final entry1 = AudiobookDuplicateEntry(
        book: book1,
        result: const DuplicateCheckResult(
          status: DuplicateStatus.possibleBookMatch,
          existingBookId: 'non-existent-id', // Will fail replacement!
        ),
        action: DuplicateAction.replace,
      );

      final book2 = makeDiscoveredBook(
        id: 'b2',
        title: 'Valid New Book',
        author: 'Author 2',
      );
      final entry2 = AudiobookDuplicateEntry(
        book: book2,
        result: const DuplicateCheckResult(status: DuplicateStatus.none),
      );

      final result = await importService.commitImportedBooks(entries: [entry1, entry2]);
      expect(result.hasErrors, isTrue);
      expect(result.errors.length, 1);
      expect(result.errors.first, contains('Failed to replace'));
      expect(result.importedBooks.length, 1);
      expect(result.importedBooks.first.title, 'Valid New Book');

      // Valid book was saved despite the other failure
      expect(datasource.getAllAudiobooks().any((b) => b.title == 'Valid New Book'), isTrue);
    });
  });
}

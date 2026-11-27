import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_scanner_service.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_metadata_service.dart';
import 'package:reading_sanctuary_app/features/audiobook/services/audiobook_artwork_service.dart';
import 'package:reading_sanctuary_app/features/audiobook/data/models/audio_track.dart';
import 'package:reading_sanctuary_app/features/audiobook/utils/audio_format_utils.dart';
import 'package:reading_sanctuary_app/features/audiobook/utils/audiobook_grouping_utils.dart';

class FakeMetadataService extends AudiobookMetadataService {
  final Map<String, AudioMetadataResult> metadataByPath;

  FakeMetadataService([this.metadataByPath = const {}]);

  @override
  Future<AudioMetadataResult> readMetadata(String filePath) async {
    final normalized = filePath.replaceAll('\\', '/');
    for (final entry in metadataByPath.entries) {
      if (entry.key.replaceAll('\\', '/') == normalized) {
        return entry.value;
      }
    }
    return const AudioMetadataResult();
  }
}

void main() {
  group('Milestone 2B — 2.6 Audio Format Detection', () {
    test('detects all supported audio formats case-insensitively', () {
      expect(AudioFormatUtils.isSupported('track.mp3'), isTrue);
      expect(AudioFormatUtils.isSupported('track.MP3'), isTrue);
      expect(AudioFormatUtils.isSupported('book.m4b'), isTrue);
      expect(AudioFormatUtils.isSupported('book.M4B'), isTrue);
      expect(AudioFormatUtils.isSupported('audio.m4a'), isTrue);
      expect(AudioFormatUtils.isSupported('sound.ogg'), isTrue);
      expect(AudioFormatUtils.isSupported('sound.oga'), isTrue);
      expect(AudioFormatUtils.isSupported('voice.opus'), isTrue);
      expect(AudioFormatUtils.isSupported('VOICE.OPUS'), isTrue);
    });

    test('rejects non-audio formats', () {
      expect(AudioFormatUtils.isSupported('cover.jpg'), isFalse);
      expect(AudioFormatUtils.isSupported('cover.png'), isFalse);
      expect(AudioFormatUtils.isSupported('info.txt'), isFalse);
      expect(AudioFormatUtils.isSupported('document.pdf'), isFalse);
      expect(AudioFormatUtils.isSupported('book.epub'), isFalse);
      expect(AudioFormatUtils.isSupported('no_extension'), isFalse);
    });
  });

  group('Milestone 2B — 2.7 & 2.8 AudiobookGroupingUtils', () {
    test('cleanBookTitle removes disc/part suffixes', () {
      expect(AudiobookGroupingUtils.cleanBookTitle('Dune (Disc 1)'), 'Dune');
      expect(AudiobookGroupingUtils.cleanBookTitle('Dune [CD 2]'), 'Dune');
      expect(AudiobookGroupingUtils.cleanBookTitle('The Way of Kings: Part 1'), 'The Way of Kings');
      expect(AudiobookGroupingUtils.cleanBookTitle('War and Peace - Part 02'), 'War and Peace');
      expect(AudiobookGroupingUtils.cleanBookTitle('The Hobbit - Volume 1'), 'The Hobbit');
      expect(AudiobookGroupingUtils.cleanBookTitle('Normal Book Title'), 'Normal Book Title');
    });

    test('isSubpartFolder detects disc/part folder naming', () {
      expect(AudiobookGroupingUtils.isSubpartFolder('CD 1'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('cd02'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('Disc 1'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('Disk-2'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('Part 1'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('Part_02'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('Vol 1'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('Volume 2'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('Side A'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('01'), isTrue);
      expect(AudiobookGroupingUtils.isSubpartFolder('1'), isTrue);

      expect(AudiobookGroupingUtils.isSubpartFolder('The Hobbit'), isFalse);
      expect(AudiobookGroupingUtils.isSubpartFolder('1984'), isFalse);
      expect(AudiobookGroupingUtils.isSubpartFolder('Audiobooks'), isFalse);
    });

    test('resolveBookDirectory resolves subpart folders to parent book folder', () {
      final root = Directory('/library/audiobooks');
      final duneCd1 = Directory('/library/audiobooks/Dune/CD 1');
      final resolved = AudiobookGroupingUtils.resolveBookDirectory(duneCd1, rootDir: root);
      expect(resolved.path.replaceAll('\\', '/'), '/library/audiobooks/Dune');

      final flatBook = Directory('/library/audiobooks/The Hobbit');
      final resolvedFlat = AudiobookGroupingUtils.resolveBookDirectory(flatBook, rootDir: root);
      expect(resolvedFlat.path.replaceAll('\\', '/'), '/library/audiobooks/The Hobbit');
    });

    test('extractDiscNumber extracts disc from folder name or file prefix', () {
      expect(AudiobookGroupingUtils.extractDiscNumber('/audiobooks/Dune/CD 2/01.mp3'), 2);
      expect(AudiobookGroupingUtils.extractDiscNumber('/audiobooks/Dune/Part 03/01.mp3'), 3);
      expect(AudiobookGroupingUtils.extractDiscNumber('/audiobooks/Dune/Disc 4/01.mp3'), 4);
      expect(AudiobookGroupingUtils.extractDiscNumber('/audiobooks/Dune/2-01 Chapter 1.mp3'), 2);
      expect(AudiobookGroupingUtils.extractDiscNumber('/audiobooks/Dune/Chapter 1.mp3'), 1);
    });

    test('extractTrackNumber parses chapter and track numbers from names', () {
      expect(AudiobookGroupingUtils.extractTrackNumber('01 - Introduction.mp3'), 1);
      expect(AudiobookGroupingUtils.extractTrackNumber('02. Chapter Two.mp3'), 2);
      expect(AudiobookGroupingUtils.extractTrackNumber('1-05 Track Five.mp3'), 5);
      expect(AudiobookGroupingUtils.extractTrackNumber('Chapter 12 - Climax.mp3'), 12);
      expect(AudiobookGroupingUtils.extractTrackNumber('Ch. 4.mp3'), 4);
      expect(AudiobookGroupingUtils.extractTrackNumber('Track 07.mp3'), 7);
      expect(AudiobookGroupingUtils.extractTrackNumber('Prologue.mp3'), isNull);
    });

    test('compareTracks orders CD 1 tracks before CD 2 tracks (prevents interleaving)', () {
      // CD 1 Track 1 vs CD 2 Track 1
      final cmp1 = AudiobookGroupingUtils.compareTracks(
        pathA: '/Dune/CD 1/01.mp3',
        nameA: '01.mp3',
        discA: 1,
        trackA: 1,
        pathB: '/Dune/CD 2/01.mp3',
        nameB: '01.mp3',
        discB: 2,
        trackB: 1,
      );
      expect(cmp1, lessThan(0));

      // CD 1 Track 2 vs CD 2 Track 1
      final cmp2 = AudiobookGroupingUtils.compareTracks(
        pathA: '/Dune/CD 1/02.mp3',
        nameA: '02.mp3',
        discA: 1,
        trackA: 2,
        pathB: '/Dune/CD 2/01.mp3',
        nameB: '01.mp3',
        discB: 2,
        trackB: 1,
      );
      expect(cmp2, lessThan(0));
    });

    test('compareTracks falls back to natural sorting when track numbers are absent', () {
      final tracks = ['Chapter 10.mp3', 'Chapter 1.mp3', 'Chapter 2.mp3'];
      tracks.sort((a, b) => AudiobookGroupingUtils.compareTracks(
        pathA: a,
        nameA: a,
        pathB: b,
        nameB: b,
      ));
      expect(tracks, ['Chapter 1.mp3', 'Chapter 2.mp3', 'Chapter 10.mp3']);
    });
  });

  group('Milestone 2B — 2.7 Book Grouping & Collision Avoidance in Scanner', () {
    test('processPickedFiles separates audiobooks with same album but different artists', () async {
      final file1 = File('/music/great_exp_dickens/01.mp3');
      final file2 = File('/music/great_exp_acker/01.mp3');

      final fakeMeta = FakeMetadataService({
        file1.path: const AudioMetadataResult(
          title: 'Chapter 1',
          album: 'Great Expectations',
          artist: 'Charles Dickens',
          trackNumber: 1,
          durationMs: 60000,
        ),
        file2.path: const AudioMetadataResult(
          title: 'Chapter 1',
          album: 'Great Expectations',
          artist: 'Kathy Acker',
          trackNumber: 1,
          durationMs: 75000,
        ),
      });

      final scanner = AudiobookScannerService(metadataService: fakeMeta);
      final books = await scanner.processPickedFiles([file1, file2]);

      expect(books.length, 2);
      expect(books.map((b) => b.author).toSet(), {'Charles Dickens', 'Kathy Acker'});
    });

    test('processPickedFiles groups multi-part loose files of the same book together', () async {
      final file1 = File('/audiobooks/Dune/CD 1/01.mp3');
      final file2 = File('/audiobooks/Dune/CD 2/01.mp3');

      final fakeMeta = FakeMetadataService({
        file1.path: const AudioMetadataResult(
          title: 'Track 1',
          album: 'Dune (Disc 1)',
          artist: 'Frank Herbert',
          trackNumber: 1,
          discNumber: 1,
          durationMs: 120000,
        ),
        file2.path: const AudioMetadataResult(
          title: 'Track 2',
          album: 'Dune (Disc 2)',
          artist: 'Frank Herbert',
          trackNumber: 1,
          discNumber: 2,
          durationMs: 130000,
        ),
      });

      final scanner = AudiobookScannerService(metadataService: fakeMeta);
      final books = await scanner.processPickedFiles([file1, file2]);

      expect(books.length, 1);
      expect(books.first.title, 'Dune');
      expect(books.first.tracks.length, 2);
      // Track 1 should be CD 1, Track 2 should be CD 2
      expect(books.first.tracks[0].discNumber, 1);
      expect(books.first.tracks[1].discNumber, 2);
      expect(books.first.tracks[0].trackOrder, 1);
      expect(books.first.tracks[1].trackOrder, 2);
      expect(books.first.totalDurationMs, 250000);
    });
  });

  group('Milestone 2B — 2.4 & 2.5 Folder Scanning with Nested Multi-Part Folders', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rs_audiobook_scan_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('scanFolder detects recursive multi-part subfolders as a single book', () async {
      // Create folder hierarchy:
      // tempDir/
      //   The Way of Kings/
      //     Part 1/
      //       01.mp3
      //       02.mp3
      //     Part 2/
      //       01.mp3
      final bookDir = Directory('${tempDir.path}/The Way of Kings');
      final part1Dir = Directory('${bookDir.path}/Part 1');
      final part2Dir = Directory('${bookDir.path}/Part 2');

      await part1Dir.create(recursive: true);
      await part2Dir.create(recursive: true);

      final f1 = File('${part1Dir.path}/01.mp3');
      final f2 = File('${part1Dir.path}/02.mp3');
      final f3 = File('${part2Dir.path}/01.mp3');

      await f1.writeAsString('audio content 1');
      await f2.writeAsString('audio content 2');
      await f3.writeAsString('audio content 3');

      final fakeMeta = FakeMetadataService({
        f1.path: const AudioMetadataResult(
          title: 'Prologue',
          album: 'The Way of Kings',
          artist: 'Brandon Sanderson',
          trackNumber: 1,
          discNumber: 1,
          durationMs: 300000,
        ),
        f2.path: const AudioMetadataResult(
          title: 'Chapter 1',
          album: 'The Way of Kings',
          artist: 'Brandon Sanderson',
          trackNumber: 2,
          discNumber: 1,
          durationMs: 400000,
        ),
        f3.path: const AudioMetadataResult(
          title: 'Chapter 2',
          album: 'The Way of Kings',
          artist: 'Brandon Sanderson',
          trackNumber: 1,
          discNumber: 2,
          durationMs: 500000,
        ),
      });

      final scanner = AudiobookScannerService(metadataService: fakeMeta);
      final discovered = await scanner.scanFolder(tempDir.path);

      expect(discovered.length, 1);
      final book = discovered.first;
      expect(book.title, 'The Way of Kings');
      expect(book.author, 'Brandon Sanderson');
      expect(book.tracks.length, 3);

      // Verify strict ordering: Part 1 Track 1, Part 1 Track 2, Part 2 Track 1
      expect(book.tracks[0].chapterTitle, 'Prologue');
      expect(book.tracks[0].trackOrder, 1);
      expect(book.tracks[0].discNumber, 1);

      expect(book.tracks[1].chapterTitle, 'Chapter 1');
      expect(book.tracks[1].trackOrder, 2);
      expect(book.tracks[1].discNumber, 1);

      expect(book.tracks[2].chapterTitle, 'Chapter 2');
      expect(book.tracks[2].trackOrder, 3);
      expect(book.tracks[2].discNumber, 2);

      expect(book.totalDurationMs, 1200000);
    });
  });

  group('Milestone 2C — 2.9 Author and Narrator Metadata Resolution', () {
    test('AudioMetadataResult preserves artist and albumArtist independently', () {
      const result = AudioMetadataResult(
        title: 'The Silent Patient',
        artist: 'Narrated by Jack Hawkins',
        albumArtist: 'Alex Michaelides',
        album: 'The Silent Patient',
      );
      expect(result.artist, 'Narrated by Jack Hawkins');
      expect(result.albumArtist, 'Alex Michaelides');
    });

    test('resolves author from albumArtist and narrator from artist with "Narrated by"', () {
      final res = AudiobookGroupingUtils.resolveAuthorAndNarrator(
        albumArtist: 'Alex Michaelides',
        artist: 'Narrated by Jack Hawkins',
      );
      expect(res.author, 'Alex Michaelides');
      expect(res.narrator, 'Jack Hawkins');
    });

    test('resolves author from albumArtist and narrator from artist with "Read by"', () {
      final res = AudiobookGroupingUtils.resolveAuthorAndNarrator(
        albumArtist: 'J.K. Rowling',
        artist: 'Read by Stephen Fry',
      );
      expect(res.author, 'J.K. Rowling');
      expect(res.narrator, 'Stephen Fry');
    });

    test('extracts narrator from embedded [Read by ...] in title or folder path', () {
      final fromTitle = AudiobookGroupingUtils.resolveAuthorAndNarrator(
        artist: 'Brandon Sanderson',
        title: 'Chapter 01 [Read by Michael Kramer]',
      );
      expect(fromTitle.author, 'Brandon Sanderson');
      expect(fromTitle.narrator, 'Michael Kramer');

      final fromPath = AudiobookGroupingUtils.resolveAuthorAndNarrator(
        artist: 'Brandon Sanderson',
        path: '/audiobooks/The Way of Kings (Narrated by Kate Reading)/01.mp3',
      );
      expect(fromPath.author, 'Brandon Sanderson');
      expect(fromPath.narrator, 'Kate Reading');
    });

    test('does not blindly infer narrator when albumArtist and artist differ without narrator cues', () {
      final res = AudiobookGroupingUtils.resolveAuthorAndNarrator(
        albumArtist: 'Various Artists',
        artist: 'Queen',
      );
      expect(res.author, 'Various Artists');
      expect(res.narrator, isNull);
    });

    test('preserves explicit narrator metadata when provided', () {
      final res = AudiobookGroupingUtils.resolveAuthorAndNarrator(
        explicitNarrator: 'Jack Hawkins',
        albumArtist: 'Alex Michaelides',
        artist: 'Alex Michaelides',
      );
      expect(res.author, 'Alex Michaelides');
      expect(res.narrator, 'Jack Hawkins');
    });

    test('leaves narrator null when metadata does not provide sufficient evidence', () {
      final res = AudiobookGroupingUtils.resolveAuthorAndNarrator(
        artist: 'J.R.R. Tolkien',
        albumArtist: 'J.R.R. Tolkien',
      );
      expect(res.author, 'J.R.R. Tolkien');
      expect(res.narrator, isNull);
    });
  });

  group('Milestone 2C — 2.10 Duration Extraction with Missing and Zero Durations', () {
    test('calculates total duration strictly from known positive track durations', () async {
      final file1 = File('/audiobooks/Book/01.mp3');
      final file2 = File('/audiobooks/Book/02.mp3');
      final file3 = File('/audiobooks/Book/03.mp3');
      final file4 = File('/audiobooks/Book/04.mp3');

      final fakeMeta = FakeMetadataService({
        file1.path: const AudioMetadataResult(
          title: 'Chapter 1',
          album: 'Mixed Book',
          artist: 'Author A',
          durationMs: 300000,
        ),
        file2.path: const AudioMetadataResult(
          title: 'Chapter 2',
          album: 'Mixed Book',
          artist: 'Author A',
          durationMs: 0,
        ),
        file3.path: const AudioMetadataResult(
          title: 'Chapter 3',
          album: 'Mixed Book',
          artist: 'Author A',
          durationMs: 500000,
        ),
        file4.path: const AudioMetadataResult(
          title: 'Chapter 4',
          album: 'Mixed Book',
          artist: 'Author A',
          durationMs: null, // missing duration
        ),
      });

      final scanner = AudiobookScannerService(metadataService: fakeMeta);
      final books = await scanner.processPickedFiles([file1, file2, file3, file4]);

      expect(books.length, 1);
      final book = books.first;
      expect(book.tracks.length, 4);

      // Verify individual durations
      expect(book.tracks[0].durationMs, 300000);
      expect(book.tracks[1].durationMs, 0);
      expect(book.tracks[2].durationMs, 500000);
      expect(book.tracks[3].durationMs, 0);

      // Verify known total duration is 800,000 ms (no arbitrary estimates added)
      expect(book.totalDurationMs, 800000);
    });
  });

  group('Milestone 2C — 2.11 & 2.12 Artwork Extraction and Priority', () {
    late Directory tempDir;
    late Directory artworkDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rs_art_test_');
      artworkDir = Directory('${tempDir.path}/covers');
      await artworkDir.create(recursive: true);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('extracts and saves embedded JPEG artwork with jpg extension', () async {
      final artworkService = AudiobookArtworkService(artworkDir: artworkDir);
      final jpegBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]);

      final savedPath = await artworkService.saveEmbeddedArtwork(jpegBytes, extension: 'jpg');
      expect(savedPath, isNotNull);
      expect(savedPath!.endsWith('.jpg'), isTrue);

      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), jpegBytes);
    });

    test('extracts and saves embedded PNG artwork with png extension', () async {
      final artworkService = AudiobookArtworkService(artworkDir: artworkDir);
      final pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]);

      final savedPath = await artworkService.saveEmbeddedArtwork(pngBytes, extension: 'png');
      expect(savedPath, isNotNull);
      expect(savedPath!.endsWith('.png'), isTrue);

      final file = File(savedPath);
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), pngBytes);
    });

    test('local cover image takes priority over embedded artwork', () async {
      final bookFolder = Directory('${tempDir.path}/The Hobbit');
      await bookFolder.create(recursive: true);

      final localCover = File('${bookFolder.path}/cover.jpg');
      await localCover.writeAsString('local cover image data');

      final audioFile = File('${bookFolder.path}/01.mp3');
      await audioFile.writeAsString('audio content');

      final embeddedBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final fakeMeta = FakeMetadataService({
        audioFile.path: AudioMetadataResult(
          title: 'Prologue',
          album: 'The Hobbit',
          artist: 'J.R.R. Tolkien',
          durationMs: 100000,
          pictureBytes: embeddedBytes,
          mimeType: 'image/jpeg',
        ),
      });

      final artworkService = AudiobookArtworkService(artworkDir: artworkDir);
      final scanner = AudiobookScannerService(
        metadataService: fakeMeta,
        artworkService: artworkService,
      );

      final discovered = await scanner.scanFolder(bookFolder.path);
      expect(discovered.length, 1);
      final book = discovered.first;

      // Verify local cover took priority
      expect(book.coverPath, localCover.path);

      // Verify no embedded artwork file was written into artworkDir
      final generatedFiles = artworkDir.listSync();
      expect(generatedFiles.isEmpty, isTrue);
    });

    test('failed or corrupt artwork extraction does not abort scanning', () async {
      final bookFolder = Directory('${tempDir.path}/Broken Art Book');
      await bookFolder.create(recursive: true);

      final audioFile = File('${bookFolder.path}/01.mp3');
      await audioFile.writeAsString('audio content');

      final fakeMeta = FakeMetadataService({
        audioFile.path: const AudioMetadataResult(
          title: 'Chapter 1',
          album: 'Broken Art Book',
          artist: 'Author B',
          durationMs: 50000,
          pictureBytes: null,
        ),
      });

      final artworkService = AudiobookArtworkService(artworkDir: artworkDir);
      final scanner = AudiobookScannerService(
        metadataService: fakeMeta,
        artworkService: artworkService,
      );

      final discovered = await scanner.scanFolder(bookFolder.path);
      expect(discovered.length, 1);
      expect(discovered.first.title, 'Broken Art Book');
      expect(discovered.first.coverPath, isNull);
    });
  });

  group('Milestone 2D — 2D.1 Rejected File Reporting', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rs_rejected_files_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('scanFolder reports non-audio files (PDF, EPUB, TXT) as unsupportedFormat and excludes local cover', () async {
      final bookFolder = Directory('${tempDir.path}/Mixed Files Book');
      await bookFolder.create(recursive: true);

      final audioFile = File('${bookFolder.path}/01.mp3');
      final coverFile = File('${bookFolder.path}/cover.jpg');
      final pdfFile = File('${bookFolder.path}/notes.pdf');
      final epubFile = File('${bookFolder.path}/book.epub');
      final txtFile = File('${bookFolder.path}/info.txt');

      await audioFile.writeAsString('audio binary content');
      await coverFile.writeAsString('cover image content');
      await pdfFile.writeAsString('pdf content');
      await epubFile.writeAsString('epub content');
      await txtFile.writeAsString('txt content');

      final fakeMeta = FakeMetadataService({
        audioFile.path: const AudioMetadataResult(
          title: 'Track 1',
          album: 'Mixed Files Book',
          artist: 'Author A',
          durationMs: 120000,
        ),
      });

      final scanner = AudiobookScannerService(metadataService: fakeMeta);
      final scanResult = await scanner.scanFolder(bookFolder.path);

      // Books should only contain the valid audio track
      expect(scanResult.books.length, 1);
      final book = scanResult.books.first;
      expect(book.tracks.length, 1);
      expect(book.tracks.first.fileName, '01.mp3');
      expect(book.coverPath, coverFile.path);

      // Rejected files should report the 3 non-audio files
      expect(scanResult.hasRejectedFiles, isTrue);
      expect(scanResult.rejectedFiles.length, 3);

      final rejectedNames = scanResult.rejectedFiles.map((r) => r.fileName).toSet();
      expect(rejectedNames, containsAll({'notes.pdf', 'book.epub', 'info.txt'}));
      expect(rejectedNames.contains('cover.jpg'), isFalse);
      expect(rejectedNames.contains('01.mp3'), isFalse);

      for (final r in scanResult.rejectedFiles) {
        expect(r.reason, RejectedFileReason.unsupportedFormat);
        expect(r.reasonLabel, contains('Unsupported format'));
      }
    });

    test('scanFolder reports zero-byte audio files as emptyFile without dropping valid tracks', () async {
      final bookFolder = Directory('${tempDir.path}/Zero Byte Book');
      await bookFolder.create(recursive: true);

      final validTrack = File('${bookFolder.path}/01_valid.mp3');
      final emptyTrack = File('${bookFolder.path}/02_empty.mp3');

      await validTrack.writeAsString('valid audio stream data');
      await emptyTrack.writeAsBytes([]); // 0 bytes

      final fakeMeta = FakeMetadataService({
        validTrack.path: const AudioMetadataResult(
          title: 'Valid Track',
          album: 'Zero Byte Book',
          artist: 'Author B',
          durationMs: 90000,
        ),
      });

      final scanner = AudiobookScannerService(metadataService: fakeMeta);
      final scanResult = await scanner.scanFolder(bookFolder.path);

      expect(scanResult.books.length, 1);
      expect(scanResult.books.first.tracks.length, 1);
      expect(scanResult.books.first.tracks.first.fileName, '01_valid.mp3');

      expect(scanResult.rejectedFiles.length, 1);
      final rejected = scanResult.rejectedFiles.first;
      expect(rejected.fileName, '02_empty.mp3');
      expect(rejected.reason, RejectedFileReason.emptyFile);
      expect(rejected.reasonLabel, contains('0 bytes'));
    });

    test('scanFolder handles unreadable or corrupt audio files gracefully', () async {
      final bookFolder = Directory('${tempDir.path}/Corrupt Track Book');
      await bookFolder.create(recursive: true);

      final track1 = File('${bookFolder.path}/01_good.mp3');
      final track2 = File('${bookFolder.path}/02_corrupt.mp3');

      await track1.writeAsString('good audio');
      await track2.writeAsString('bad corrupted audio header');

      // Create a metadata service that throws for track2
      final fakeMeta = _ThrowingMetadataService(
        throwingPaths: {track2.path.replaceAll('\\', '/')},
        normalResults: {
          track1.path: const AudioMetadataResult(
            title: 'Good Track',
            album: 'Corrupt Track Book',
            artist: 'Author C',
            durationMs: 45000,
          ),
        },
      );

      final scanner = AudiobookScannerService(metadataService: fakeMeta);
      final scanResult = await scanner.scanFolder(bookFolder.path);

      expect(scanResult.books.length, 1);
      expect(scanResult.books.first.tracks.length, 1);
      expect(scanResult.books.first.tracks.first.fileName, '01_good.mp3');

      expect(scanResult.rejectedFiles.length, 1);
      final rejected = scanResult.rejectedFiles.first;
      expect(rejected.fileName, '02_corrupt.mp3');
      expect(rejected.reason, RejectedFileReason.unreadable);
      expect(rejected.reasonLabel, contains('Unreadable'));
    });

    test('processPickedFiles reports empty, unsupported, and inaccessible files accurately', () async {
      final validFile = File('${tempDir.path}/track1.mp3');
      final emptyFile = File('${tempDir.path}/track2_empty.mp3');
      final unsupportedFile = File('${tempDir.path}/notes.pdf');
      final missingFile = File('${tempDir.path}/non_existent.m4a');

      await validFile.writeAsString('audio bytes');
      await emptyFile.writeAsBytes([]);
      await unsupportedFile.writeAsString('pdf bytes');
      // missingFile is not created

      final fakeMeta = FakeMetadataService({
        validFile.path: const AudioMetadataResult(
          title: 'Track 1',
          album: 'Picked Album',
          artist: 'Picked Artist',
          durationMs: 80000,
        ),
      });

      final scanner = AudiobookScannerService(metadataService: fakeMeta);
      final scanResult = await scanner.processPickedFiles([
        validFile,
        emptyFile,
        unsupportedFile,
        missingFile,
      ]);

      expect(scanResult.books.length, 1);
      expect(scanResult.books.first.tracks.length, 1);
      expect(scanResult.books.first.tracks.first.fileName, 'track1.mp3');

      expect(scanResult.rejectedFiles.length, 3);
      final rejectedMap = {
        for (final r in scanResult.rejectedFiles) r.fileName: r.reason,
      };

      expect(rejectedMap['track2_empty.mp3'], RejectedFileReason.emptyFile);
      expect(rejectedMap['notes.pdf'], RejectedFileReason.unsupportedFormat);
      expect(rejectedMap['non_existent.m4a'], RejectedFileReason.inaccessible);
    });

    test('AudiobookScanResult implements ListBase and exposes totalTracks and hasRejectedFiles', () {
      final book1 = DiscoveredBook(
        id: '1',
        title: 'Book 1',
        author: 'Author 1',
        tracks: const [
          AudioTrack(id: 't1', audiobookId: '1', filePath: '/t1.mp3', fileName: 't1.mp3', trackOrder: 1, durationMs: 1000, format: 'MP3'),
          AudioTrack(id: 't2', audiobookId: '1', filePath: '/t2.mp3', fileName: 't2.mp3', trackOrder: 2, durationMs: 2000, format: 'MP3'),
        ],
        totalDurationMs: 3000,
      );

      const rejected = RejectedAudioFile(
        fileName: 'bad.txt',
        filePath: '/bad.txt',
        reason: RejectedFileReason.unsupportedFormat,
      );

      final result = AudiobookScanResult(
        books: [book1],
        rejectedFiles: [rejected],
      );

      // ListBase compatibility: length, index, iteration
      expect(result.length, 1);
      expect(result[0].title, 'Book 1');
      expect(result.first.author, 'Author 1');
      expect(result.toList().length, 1);

      // Specific properties
      expect(result.hasRejectedFiles, isTrue);
      expect(result.hasBooks, isTrue);
      expect(result.totalTracks, 2);
      expect(result.rejectedFiles.first.fileName, 'bad.txt');
    });
  });
}

class _ThrowingMetadataService extends AudiobookMetadataService {
  final Set<String> throwingPaths;
  final Map<String, AudioMetadataResult> normalResults;

  _ThrowingMetadataService({
    required this.throwingPaths,
    required this.normalResults,
  });

  @override
  Future<AudioMetadataResult> readMetadata(String filePath) async {
    final normalized = filePath.replaceAll('\\', '/');
    if (throwingPaths.contains(normalized)) {
      throw const FileSystemException('Corrupt audio header');
    }
    for (final entry in normalResults.entries) {
      if (entry.key.replaceAll('\\', '/') == normalized) {
        return entry.value;
      }
    }
    return const AudioMetadataResult();
  }
}

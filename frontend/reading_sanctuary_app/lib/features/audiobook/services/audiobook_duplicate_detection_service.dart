import 'dart:io';
import '../data/datasources/audiobook_local_datasource.dart';
import '../data/models/audiobook.dart';
import '../data/models/audio_track.dart';
import 'audiobook_scanner_service.dart';

enum DuplicateStatus {
  none,
  exactFileMatch,
  possibleBookMatch,
}

enum DuplicateAction {
  skip,
  importAnyway,
  replace,
}

class DuplicateCheckResult {
  final DuplicateStatus status;
  final String? existingBookId;
  final String? existingBookTitle;
  final String? existingAuthor;
  final List<String> matchingFilePaths;
  final String? message;

  const DuplicateCheckResult({
    required this.status,
    this.existingBookId,
    this.existingBookTitle,
    this.existingAuthor,
    this.matchingFilePaths = const [],
    this.message,
  });

  bool get isDuplicate => status != DuplicateStatus.none;

  bool get isExactMatch => status == DuplicateStatus.exactFileMatch;

  bool get isPossibleMatch => status == DuplicateStatus.possibleBookMatch;
}

class AudiobookDuplicateEntry {
  final DiscoveredBook book;
  final DuplicateCheckResult result;
  final DuplicateAction? action;

  const AudiobookDuplicateEntry({
    required this.book,
    required this.result,
    this.action,
  });

  AudiobookDuplicateEntry copyWith({
    DuplicateAction? action,
  }) {
    return AudiobookDuplicateEntry(
      book: book,
      result: result,
      action: action ?? this.action,
    );
  }
}

class AudiobookDuplicateDetectionService {
  final AudiobookLocalDatasource _dataSource;

  AudiobookDuplicateDetectionService({
    required AudiobookLocalDatasource dataSource,
  }) : _dataSource = dataSource;

  /// Normalizes a file path for reliable duplicate comparison.
  /// - Converts backslashes to forward slashes.
  /// - Resolves symbolic links and relative segments (. and ..).
  /// - Preserves UNC network paths (//server/share).
  /// - Applies case-insensitive comparison on Windows.
  static String normalizePath(String rawPath) {
    if (rawPath.trim().isEmpty) return '';
    var pathStr = rawPath.trim();

    try {
      final file = File(pathStr);
      if (file.existsSync()) {
        try {
          pathStr = file.resolveSymbolicLinksSync();
        } catch (_) {
          pathStr = file.absolute.path;
        }
      } else {
        pathStr = file.absolute.path;
      }
    } catch (_) {}

    pathStr = pathStr.replaceAll('\\', '/');

    final isUnc = pathStr.startsWith('//');
    final isRoot = pathStr.startsWith('/') && !isUnc;

    // Split and collapse . and ..
    final segments = <String>[];
    for (final seg in pathStr.split('/')) {
      if (seg.isEmpty || seg == '.') {
        continue;
      } else if (seg == '..') {
        if (segments.isNotEmpty && segments.last != '..') {
          segments.removeLast();
        }
      } else {
        segments.add(seg);
      }
    }

    var normalized = (isUnc ? '//' : (isRoot ? '/' : '')) + segments.join('/');

    // Case-insensitive comparison on Windows
    if (Platform.isWindows) {
      normalized = normalized.toLowerCase();
    }

    return normalized;
  }

  /// Normalizes title and author text for book duplicate comparison.
  /// - Trims leading/trailing whitespace.
  /// - Collapses multiple spaces into a single space.
  /// - Converts to lowercase.
  /// - Removes harmless leading/trailing punctuation (. , ; : - _).
  /// - Preserves edition, subtitle, and meaningful words.
  static String normalizeText(String? text) {
    if (text == null) return '';
    var s = text.trim();
    if (s.isEmpty) return '';

    // Collapse repeated whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ');

    // Strip harmless leading and trailing punctuation
    s = s.replaceAll(RegExp(r'^[.,;:_\-\s]+|[.,;:_\-\s]+$'), '');

    return s.toLowerCase();
  }

  /// Checks discovered audiobooks against the existing library.
  /// Builds lookup indexes to compare books efficiently.
  Future<List<AudiobookDuplicateEntry>> checkDuplicates({
    required List<DiscoveredBook> discoveredBooks,
  }) async {
    if (discoveredBooks.isEmpty) {
      return [];
    }

    await _dataSource.init();
    final existingBooks = _dataSource.getAllAudiobooks();

    if (existingBooks.isEmpty) {
      return discoveredBooks.map((book) {
        return AudiobookDuplicateEntry(
          book: book,
          result: const DuplicateCheckResult(status: DuplicateStatus.none),
        );
      }).toList();
    }

    // Index 1: Map normalizedFilePath -> (Audiobook existingBook, AudioTrack existingTrack)
    final trackPathIndex = <String, MapEntry<Audiobook, AudioTrack>>{};

    // Index 2: Map compoundKey '$normTitle:::$normAuthor' -> Audiobook
    final metadataIndex = <String, Audiobook>{};

    for (final book in existingBooks) {
      final normTitle = normalizeText(book.title);
      final normAuthor = normalizeText(book.author);

      // Rule 3 & 4: Only index if BOTH title and author are non-empty
      if (normTitle.isNotEmpty && normAuthor.isNotEmpty) {
        final compoundKey = '$normTitle:::$normAuthor';
        metadataIndex.putIfAbsent(compoundKey, () => book);
      }

      final tracks = _dataSource.getTracksForBook(book.id);
      for (final track in tracks) {
        final normPath = normalizePath(track.filePath);
        if (normPath.isNotEmpty) {
          trackPathIndex[normPath] = MapEntry(book, track);
        }
      }
    }

    final entries = <AudiobookDuplicateEntry>[];

    for (final discovered in discoveredBooks) {
      // Priority 1: Check for exact file matches among the discovered book's tracks
      final matchingPaths = <String>[];
      Audiobook? fileMatchedBook;

      for (final track in discovered.tracks) {
        final normPath = normalizePath(track.filePath);
        if (normPath.isNotEmpty && trackPathIndex.containsKey(normPath)) {
          matchingPaths.add(track.filePath);
          fileMatchedBook ??= trackPathIndex[normPath]!.key;
        }
      }

      if (matchingPaths.isNotEmpty && fileMatchedBook != null) {
        entries.add(AudiobookDuplicateEntry(
          book: discovered,
          result: DuplicateCheckResult(
            status: DuplicateStatus.exactFileMatch,
            existingBookId: fileMatchedBook.id,
            existingBookTitle: fileMatchedBook.title,
            existingAuthor: fileMatchedBook.author,
            matchingFilePaths: matchingPaths,
            message: 'Existing audiobook "${fileMatchedBook.title}" already contains one or more of these files.',
          ),
        ));
        continue;
      }

      // Priority 2: Check for possible book match via normalized title AND author
      final discTitle = normalizeText(discovered.title);
      final discAuthor = normalizeText(discovered.author);

      if (discTitle.isNotEmpty && discAuthor.isNotEmpty) {
        final compoundKey = '$discTitle:::$discAuthor';
        if (metadataIndex.containsKey(compoundKey)) {
          final matchedBook = metadataIndex[compoundKey]!;
          entries.add(AudiobookDuplicateEntry(
            book: discovered,
            result: DuplicateCheckResult(
              status: DuplicateStatus.possibleBookMatch,
              existingBookId: matchedBook.id,
              existingBookTitle: matchedBook.title,
              existingAuthor: matchedBook.author,
              message: 'An audiobook with the same title and author ("${matchedBook.title}" by ${matchedBook.author}) already exists in your library.',
            ),
          ));
          continue;
        }
      }

      // Priority 3, 4, 5: No duplicate
      entries.add(AudiobookDuplicateEntry(
        book: discovered,
        result: const DuplicateCheckResult(status: DuplicateStatus.none),
      ));
    }

    return entries;
  }
}

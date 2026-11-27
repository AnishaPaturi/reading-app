import 'dart:io';

class AuthorNarratorResult {
  final String author;
  final String? narrator;

  const AuthorNarratorResult({
    required this.author,
    this.narrator,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthorNarratorResult &&
          runtimeType == other.runtimeType &&
          author == other.author &&
          narrator == other.narrator;

  @override
  int get hashCode => author.hashCode ^ (narrator?.hashCode ?? 0);

  @override
  String toString() => 'AuthorNarratorResult(author: $author, narrator: $narrator)';
}

class AudiobookGroupingUtils {
  /// Natural alphanumeric sorting comparator (e.g. "Track 2" < "Track 10")
  static int naturalCompare(String a, String b) {
    final regex = RegExp(r'(\d+|\D+)');
    final aMatches = regex.allMatches(a).map((m) => m.group(0)!).toList();
    final bMatches = regex.allMatches(b).map((m) => m.group(0)!).toList();

    final minLength = aMatches.length < bMatches.length ? aMatches.length : bMatches.length;

    for (var i = 0; i < minLength; i++) {
      final aPart = aMatches[i];
      final bPart = bMatches[i];

      final aNum = int.tryParse(aPart);
      final bNum = int.tryParse(bPart);

      if (aNum != null && bNum != null) {
        final cmp = aNum.compareTo(bNum);
        if (cmp != 0) return cmp;
      } else {
        final cmp = aPart.toLowerCase().compareTo(bPart.toLowerCase());
        if (cmp != 0) return cmp;
      }
    }

    return aMatches.length.compareTo(bMatches.length);
  }

  /// Clean filename into a reasonable track / chapter title
  static String cleanTrackTitle(String fileName) {
    var name = fileName;
    final dotIdx = name.lastIndexOf('.');
    if (dotIdx != -1) {
      name = name.substring(0, dotIdx);
    }

    final originalWithoutExt = name;

    // Strip leading track numbers like "01 - ", "01. ", "01 ", "1-01 ", "Chapter 01 - "
    name = name.replaceFirst(
      RegExp(
        r'^(?:(?:\d{1,2}[-\.])?\d+[\s\.\-_]+|(?:chapter|track|ch)[\s\.\-_]*\d+[\s\.\-_]*)',
        caseSensitive: false,
      ),
      '',
    );
    name = name.trim();
    if (name.isEmpty) {
      return originalWithoutExt.isEmpty ? fileName : originalWithoutExt;
    }
    return name;
  }

  /// Clean book title by removing multi-disc or multi-part suffixes
  /// e.g. "Dune (Disc 1)" -> "Dune", "War and Peace - Part 2" -> "War and Peace"
  static String cleanBookTitle(String title) {
    var clean = title.trim();
    clean = clean.replaceFirst(
      RegExp(
        r'[\s\-_:,]*(?:\(|\[)?(?:cd|disc|disk|part|vol|volume|section|side)[\s\.\-_]*\d+(?:\)|\])?$',
        caseSensitive: false,
      ),
      '',
    );
    return clean.trim().isEmpty ? title.trim() : clean.trim();
  }

  /// Checks if a directory name signifies a disc or subpart folder (e.g. "CD 1", "Part 2", "01")
  static bool isSubpartFolder(String dirName) {
    final clean = dirName.trim();
    if (clean.isEmpty) return false;
    final subpartRegex = RegExp(
      r'^(?:cd|disc|disk|part|vol|volume|section|side)[\s\.\-_]*(\d+|[a-z]+|[ivxlcdm]+)$|^\d{1,2}$',
      caseSensitive: false,
    );
    return subpartRegex.hasMatch(clean);
  }

  /// Checks if a directory is a container for subparts (e.g. "CDs", "Discs", "Parts")
  static bool isSubpartContainer(String dirName) {
    final clean = dirName.trim();
    if (clean.isEmpty) return false;
    final containerRegex = RegExp(
      r'^(?:cds|discs|disks|parts|volumes)$',
      caseSensitive: false,
    );
    return containerRegex.hasMatch(clean);
  }

  /// Resolves the canonical audiobook directory given a folder, stepping up if inside a subpart or container folder
  static Directory resolveBookDirectory(Directory folder, {Directory? rootDir}) {
    var current = folder;
    while (current.parent.path != current.path) {
      final name = current.uri.pathSegments.where((s) => s.isNotEmpty).lastOrNull ?? '';
      final isSub = isSubpartFolder(name) || isSubpartContainer(name);
      if (!isSub) {
        break;
      }
      if (rootDir != null && current.path == rootDir.path) {
        break;
      }
      final parent = current.parent;
      current = parent;
      if (rootDir != null && current.path == rootDir.path) {
        break;
      }
    }
    return current;
  }

  /// Resolves canonical book directory path from an individual file path
  static String resolveBookDirectoryPath(String filePath) {
    final file = File(filePath);
    return resolveBookDirectory(file.parent).path;
  }

  /// Extract disc/part number from path or filename
  static int extractDiscNumber(String path) {
    final match = RegExp(
      r'(?:cd|disc|disk|part|vol|volume|section|side)[\s\.\-_]*(\d+)',
      caseSensitive: false,
    ).firstMatch(path);
    if (match != null) {
      final numStr = match.group(1);
      if (numStr != null) {
        final val = int.tryParse(numStr);
        if (val != null && val > 0) return val;
      }
    }

    final fileName = path.split(RegExp(r'[/\\]')).last;
    final prefixMatch = RegExp(r'^(\d{1,2})-\d{1,3}[\s\.\-_]').firstMatch(fileName);
    if (prefixMatch != null) {
      final val = int.tryParse(prefixMatch.group(1)!);
      if (val != null && val > 0) return val;
    }

    return 1;
  }

  /// Extract track number from chapter title or filename
  static int? extractTrackNumber(String text) {
    final discTrackMatch = RegExp(r'^\d{1,2}-(\d{1,3})[\s\.\-_]').firstMatch(text);
    if (discTrackMatch != null) {
      final val = int.tryParse(discTrackMatch.group(1)!);
      if (val != null && val > 0) return val;
    }

    final namedMatch = RegExp(
      r'(?:chapter|track|ch)[\s\.\-_]*(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (namedMatch != null) {
      final val = int.tryParse(namedMatch.group(1)!);
      if (val != null && val > 0) return val;
    }

    final leadingMatch = RegExp(r'^(\d{1,3})[\s\.\-_]').firstMatch(text);
    if (leadingMatch != null) {
      final val = int.tryParse(leadingMatch.group(1)!);
      if (val != null && val > 0) return val;
    }

    return null;
  }

  /// Multi-tier track comparator:
  /// 1. Disc order (discNumber)
  /// 2. Track order (trackNumber)
  /// 3. Alphanumeric natural filename comparison
  /// 4. Fallback natural path comparison
  static int compareTracks({
    required String pathA,
    required String nameA,
    int? discA,
    int? trackA,
    required String pathB,
    required String nameB,
    int? discB,
    int? trackB,
  }) {
    final dA = (discA != null && discA > 0) ? discA : extractDiscNumber(pathA);
    final dB = (discB != null && discB > 0) ? discB : extractDiscNumber(pathB);
    if (dA != dB) {
      return dA.compareTo(dB);
    }

    final tA = (trackA != null && trackA > 0) ? trackA : extractTrackNumber(nameA);
    final tB = (trackB != null && trackB > 0) ? trackB : extractTrackNumber(nameB);
    if (tA != null && tB != null && tA != tB) {
      return tA.compareTo(tB);
    }

    final nameCmp = naturalCompare(nameA, nameB);
    if (nameCmp != 0) return nameCmp;

    return naturalCompare(pathA, pathB);
  }

  static final _narratorPrefixRegex = RegExp(
    r'^(?:narrated\s+by|read\s+by|narrator\s*:)[\s\-_:]*',
    caseSensitive: false,
  );

  static final _embeddedNarratorRegex = RegExp(
    r'(?:\[|\()\s*(?:read|narrated)\s+by[\s\-_:]+([^\)\]\n\r]+?)\s*(?:\]|\))',
    caseSensitive: false,
  );

  static final _audiobookNarratorCueRegex = RegExp(
    r'\b(?:narrator|reader|voice|read\s+by|narrated\s+by)\b',
    caseSensitive: false,
  );

  /// Resolves the author and narrator from metadata fields, adhering to evidence-based extraction rules:
  /// 1. Explicit narrator metadata takes priority.
  /// 2. Recognized "Read by" / "Narrated by" patterns in artist, albumArtist, title, or path.
  /// 3. If albumArtist and artist differ, only infer narrator if artist has narrator cues.
  /// 4. If no sufficient evidence exists, narrator remains null.
  static AuthorNarratorResult resolveAuthorAndNarrator({
    String? artist,
    String? albumArtist,
    String? explicitNarrator,
    String? title,
    String? path,
    String fallbackAuthor = 'Unknown Author',
  }) {
    final cleanArtist = artist?.trim();
    final cleanAlbumArtist = albumArtist?.trim();
    String? resolvedNarrator = explicitNarrator?.trim().isNotEmpty == true
        ? explicitNarrator!.trim()
        : null;

    // 1. Check if artist has explicit "Read by / Narrated by" prefix
    if (resolvedNarrator == null && cleanArtist != null) {
      if (_narratorPrefixRegex.hasMatch(cleanArtist)) {
        resolvedNarrator = cleanArtist.replaceFirst(_narratorPrefixRegex, '').trim();
      }
    }

    // 2. Check if albumArtist has explicit "Read by / Narrated by" prefix
    if (resolvedNarrator == null && cleanAlbumArtist != null) {
      if (_narratorPrefixRegex.hasMatch(cleanAlbumArtist)) {
        resolvedNarrator = cleanAlbumArtist.replaceFirst(_narratorPrefixRegex, '').trim();
      }
    }

    // 3. Check for embedded [Read by ...] or (Narrated by ...) in title or path
    if (resolvedNarrator == null && title != null) {
      final match = _embeddedNarratorRegex.firstMatch(title);
      if (match != null) {
        resolvedNarrator = match.group(1)?.trim();
      }
    }

    if (resolvedNarrator == null && path != null) {
      final match = _embeddedNarratorRegex.firstMatch(path);
      if (match != null) {
        resolvedNarrator = match.group(1)?.trim();
      }
    }

    // 4. If albumArtist and artist differ, check if artist has audiobook narrator cues
    if (resolvedNarrator == null &&
        cleanAlbumArtist != null &&
        cleanAlbumArtist.isNotEmpty &&
        cleanArtist != null &&
        cleanArtist.isNotEmpty &&
        cleanAlbumArtist.toLowerCase() != cleanArtist.toLowerCase()) {
      if (_audiobookNarratorCueRegex.hasMatch(cleanArtist)) {
        var n = cleanArtist.replaceFirst(_narratorPrefixRegex, '');
        n = n.replaceAll(RegExp(r'[\(\)\[\]]'), '').trim();
        n = n.replaceFirst(RegExp(r'\s*narrator\s*$', caseSensitive: false), '').trim();
        if (n.isNotEmpty) {
          resolvedNarrator = n;
        }
      }
    }

    // Determine the author
    String candidateAuthor;
    if (cleanArtist != null && _narratorPrefixRegex.hasMatch(cleanArtist)) {
      candidateAuthor = (cleanAlbumArtist != null && cleanAlbumArtist.isNotEmpty)
          ? cleanAlbumArtist
          : fallbackAuthor;
    } else if (cleanAlbumArtist != null && cleanAlbumArtist.isNotEmpty) {
      candidateAuthor = cleanAlbumArtist;
    } else if (cleanArtist != null && cleanArtist.isNotEmpty) {
      candidateAuthor = cleanArtist;
    } else {
      candidateAuthor = fallbackAuthor;
    }

    // Clean author by removing embedded (Read by ...) or [Narrated by ...]
    candidateAuthor = candidateAuthor.replaceAll(_embeddedNarratorRegex, '').trim();
    if (candidateAuthor.endsWith('-') || candidateAuthor.endsWith(':')) {
      candidateAuthor = candidateAuthor.substring(0, candidateAuthor.length - 1).trim();
    }
    if (candidateAuthor.isEmpty) {
      candidateAuthor = fallbackAuthor;
    }

    // Clean narrator brackets if present
    if (resolvedNarrator != null) {
      resolvedNarrator = resolvedNarrator.replaceAll(RegExp(r'^[\[\(]+|[\]\)]+$'), '').trim();
      if (resolvedNarrator.isEmpty) {
        resolvedNarrator = null;
      }
    }

    return AuthorNarratorResult(
      author: candidateAuthor,
      narrator: resolvedNarrator,
    );
  }
}

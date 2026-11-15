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

    // Strip leading track numbers like "01 - ", "01. ", "01 ", "Chapter 01 - "
    name = name.replaceFirst(RegExp(r'^((\d+[\s\.\-_]+)|(chapter[\s\-_]*\d+[\s\.\-_]*))', caseSensitive: false), '');
    name = name.trim();
    if (name.isEmpty) {
      return fileName;
    }
    return name;
  }
}

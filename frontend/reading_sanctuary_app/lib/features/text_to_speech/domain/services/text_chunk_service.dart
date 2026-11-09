class TextChunkService {
  static const int maxChunkLength = 2500;

  List<String> splitText(String text) {
    final paragraphs = text
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final chunks = <String>[];
    var current = StringBuffer();

    for (final paragraph in paragraphs) {
      if (paragraph.length > maxChunkLength) {
        if (current.isNotEmpty) {
          chunks.add(current.toString());
          current = StringBuffer();
        }

        for (var i = 0; i < paragraph.length; i += maxChunkLength) {
          final end = (i + maxChunkLength < paragraph.length)
              ? i + maxChunkLength
              : paragraph.length;
          chunks.add(paragraph.substring(i, end));
        }
        continue;
      }

      if (current.length + paragraph.length > maxChunkLength) {
        chunks.add(current.toString());
        current = StringBuffer();
      }

      if (current.isNotEmpty) {
        current.write('\n\n');
      }

      current.write(paragraph);
    }

    if (current.isNotEmpty) {
      chunks.add(current.toString());
    }

    return chunks;
  }
}

import 'package:flutter/material.dart';

import '../../../../shared/models/book.dart';
import '../../../reader/domain/reading_progress.dart';
import 'enhanced_currently_reading_card.dart';

class CurrentlyReadingCarousel extends StatelessWidget {
  final List<Book> books;
  final Map<String, ReadingProgress> progressMap;
  final void Function(Book book, ReadingProgress? progress) onContinueReading;

  const CurrentlyReadingCarousel({
    super.key,
    required this.books,
    required this.progressMap,
    required this.onContinueReading,
  });

  ReadingProgress? _findProgress(Book book) {
    for (final f in book.files) {
      if (progressMap.containsKey(f.id)) {
        return progressMap[f.id];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final count = books.length;

    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (int i = 0; i < count; i++) ...[
          _buildPage(context, books[i]),
          if (i < count - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildPage(BuildContext context, Book book) {
    final progress = _findProgress(book);
    return EnhancedCurrentlyReadingCard(
      key: ValueKey(book.id),
      book: book,
      progress: progress,
      onContinue: () => onContinueReading(book, progress),
    );
  }
}

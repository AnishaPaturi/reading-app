import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../reader/domain/reading_progress.dart';
import 'enhanced_currently_reading_card.dart';

class CurrentlyReadingCarousel extends StatefulWidget {
  final List<Book> books;
  final Map<String, ReadingProgress> progressMap;
  final void Function(Book book, ReadingProgress? progress) onContinueReading;

  const CurrentlyReadingCarousel({
    super.key,
    required this.books,
    required this.progressMap,
    required this.onContinueReading,
  });

  @override
  State<CurrentlyReadingCarousel> createState() => _CurrentlyReadingCarouselState();
}

class _CurrentlyReadingCarouselState extends State<CurrentlyReadingCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index >= 0 && index < widget.books.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  ReadingProgress? _findProgress(Book book) {
    for (final f in book.files) {
      if (widget.progressMap.containsKey(f.id)) {
        return widget.progressMap[f.id];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.books.length;

    if (count == 0) {
      return const SizedBox.shrink();
    }

    if (count == 1) {
      final book = widget.books.first;
      final progress = _findProgress(book);
      return EnhancedCurrentlyReadingCard(
        book: book,
        progress: progress,
        onContinue: () => widget.onContinueReading(book, progress),
      );
    }

    return Column(
      children: [
        // Carousel Header with Navigation Arrows & Indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Book ${_currentIndex + 1} of $count',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.textMuted,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Previous Book',
                    onPressed: _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
                  ),
                  Row(
                    children: List.generate(count, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: isActive ? 16 : 6,
                        decoration: BoxDecoration(
                          color: isActive ? ClayColors.deepPurple : const Color(0xFFDDD2F5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Next Book',
                    onPressed: _currentIndex < count - 1 ? () => _goTo(_currentIndex + 1) : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Animated PageView
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: SizedBox(
            // Sized appropriately for the card
            child: _buildPage(widget.books[_currentIndex]),
          ),
        ),
      ],
    );
  }

  Widget _buildPage(Book book) {
    final progress = _findProgress(book);
    return EnhancedCurrentlyReadingCard(
      key: ValueKey(book.id),
      book: book,
      progress: progress,
      onContinue: () => widget.onContinueReading(book, progress),
    );
  }
}

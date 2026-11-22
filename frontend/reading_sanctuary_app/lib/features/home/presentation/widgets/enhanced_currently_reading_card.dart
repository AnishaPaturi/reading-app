import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../../../shared/utils/book_file_navigation.dart';
import '../../../library/theme/bookshelf_theme.dart';
import '../../../reader/domain/reading_progress.dart';

class EnhancedCurrentlyReadingCard extends ConsumerStatefulWidget {
  final Book book;
  final ReadingProgress? progress;
  final VoidCallback? onContinue;

  const EnhancedCurrentlyReadingCard({
    super.key,
    required this.book,
    this.progress,
    this.onContinue,
  });

  @override
  ConsumerState<EnhancedCurrentlyReadingCard> createState() => _EnhancedCurrentlyReadingCardState();
}

class _EnhancedCurrentlyReadingCardState extends ConsumerState<EnhancedCurrentlyReadingCard> {
  bool _isDescriptionExpanded = false;

  void _incrementPage(int delta, int currentPage, int totalPages) {
    final newPage = (currentPage + delta).clamp(0, totalPages);
    if (newPage != currentPage) {
      ref.read(booksProvider.notifier).setPage(widget.book.id, newPage);
    }
  }

  void _onSliderChanged(double value, int totalPages) {
    final newPage = (value * totalPages).round().clamp(0, totalPages);
    ref.read(booksProvider.notifier).setPage(widget.book.id, newPage);
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final progress = widget.progress;
    final palette = BookshelfTheme.paletteForId(book.id);

    final int totalPages = (progress?.totalPages != null && progress!.totalPages! > 0)
        ? progress.totalPages!
        : (book.pages > 0 ? book.pages : 100);

    final int currentPage = (progress?.currentPage != null && progress!.currentPage! > 0)
        ? progress.currentPage!.clamp(0, totalPages)
        : (book.currentPage > 0 ? book.currentPage.clamp(0, totalPages) : 0);

    final double progressFraction = totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
    final int progressPct = (progressFraction * 100).round();

    // Start date & days spent reading
    final startDate = book.startDate ?? book.addedAt;
    final now = DateTime.now();
    final daysSpent = now.difference(startDate).inDays.clamp(1, 9999);

    // Average pages per day
    final double avgPagesPerDay = daysSpent > 0 ? (currentPage / daysSpent) : 0.0;
    final int remainingPages = (totalPages - currentPage).clamp(0, totalPages);

    // Estimated remaining days
    String remainingDaysText;
    if (avgPagesPerDay > 0.1 && remainingPages > 0) {
      final daysRem = (remainingPages / avgPagesPerDay).ceil();
      remainingDaysText = '$daysRem ${daysRem == 1 ? 'day' : 'days'}';
    } else if (remainingPages == 0) {
      remainingDaysText = 'Completed';
    } else {
      remainingDaysText = 'Not enough reading data';
    }

    // Format label
    final isAudio = book.formats.contains(BookFormat.audiobook) && !book.formats.contains(BookFormat.ebook);
    final formatLabel = isAudio ? 'Audiobook' : 'eBook';

    return ClayCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cover, Title, Author, Genre & Format
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClayBookMini(
                title: book.title,
                color: palette.base,
                width: 68,
                height: 96,
                hasHeart: (book.rating ?? 0) >= 4.0,
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: ClayColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ClayColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Genre & Format Tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECE5FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            book.genre,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ClayColors.primaryPurple,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAudio ? Icons.headphones_rounded : Icons.menu_book_rounded,
                                size: 12,
                                color: const Color(0xFF0284C7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0369A1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Progress percentage & Page counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progressPct% Completed',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.coral,
                ),
              ),
              Text(
                'Page $currentPage of $totalPages',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 3. Interactive Progress Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              activeTrackColor: ClayColors.coral,
              inactiveTrackColor: const Color(0xFFEDE6FA),
              thumbColor: ClayColors.coral,
              overlayColor: ClayColors.coral.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: progressFraction,
              onChanged: (v) => _onSliderChanged(v, totalPages),
            ),
          ),

          // 4. Page Increase/Decrease Stepper Controls [-] [Page] [+]
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                icon: const Icon(Icons.remove, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1EDF9),
                  foregroundColor: ClayColors.deepPurple,
                  minimumSize: const Size(36, 36),
                ),
                tooltip: 'Previous Page',
                onPressed: currentPage > 0
                    ? () => _incrementPage(-1, currentPage, totalPages)
                    : null,
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDD2F5)),
                ),
                child: Text(
                  'Page $currentPage',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ClayColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              IconButton.filledTonal(
                icon: const Icon(Icons.add, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF1EDF9),
                  foregroundColor: ClayColors.deepPurple,
                  minimumSize: const Size(36, 36),
                ),
                tooltip: 'Next Page',
                onPressed: currentPage < totalPages
                    ? () => _incrementPage(1, currentPage, totalPages)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEDE6FA)),
          const SizedBox(height: 12),

          // 5. Reading statistics: Start Date, Days Spent, Avg pages/day, Estimated remaining
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetaItem('Started', DateFormat.yMMMd().format(startDate)),
                    _buildMetaItem('Days Spent', '$daysSpent ${daysSpent == 1 ? 'day' : 'days'}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetaItem('Average', '${avgPagesPerDay.toStringAsFixed(1)} pages/day'),
                    _buildMetaItem('Estimated Remaining', remainingDaysText),
                  ],
                ),
              ],
            ),
          ),

          // 6. Expandable Book Description
          if (book.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.description,
                      maxLines: _isDescriptionExpanded ? 20 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.4,
                        color: ClayColors.textDark.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isDescriptionExpanded ? 'Read less ▲' : 'Read more ▼',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.primaryPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 7. Action Button
          ClayPillButton(
            text: 'Continue Reading  →',
            height: 38,
            fontSize: 13,
            color: ClayColors.deepPurple,
            textColor: Colors.white,
            onTap: widget.onContinue ?? () => openBookDocument(context, book),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: ClayColors.textMuted,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ClayColors.textDark,
          ),
        ),
      ],
    );
  }
}

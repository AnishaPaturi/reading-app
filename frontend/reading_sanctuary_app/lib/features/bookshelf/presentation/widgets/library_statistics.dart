import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';

class LibraryStatistics extends StatefulWidget {
  final int totalBooks;
  final int readCount;
  final int readingCount;
  final int? totalShelves;
  final List<Book> allBooks;

  const LibraryStatistics({
    super.key,
    required this.totalBooks,
    int? readCount,
    int? readingCount,
    this.totalShelves,
    int? readThisYear,
    this.allBooks = const [],
  })  : readCount = readCount ?? readThisYear ?? 0,
        readingCount = readingCount ?? 0;

  @override
  State<LibraryStatistics> createState() => _LibraryStatisticsState();
}

class _LibraryStatisticsState extends State<LibraryStatistics> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // 1. Total books
    final total = widget.totalBooks;

    // 2. Completed book count
    final completed = widget.readCount;

    // 3. Completion percentage
    final double completionPct = total > 0 ? ((completed / total) * 100.0) : 0.0;

    // 4. Currently reading count
    final currentlyReading = widget.readingCount;

    // 5. Want to Read count
    final wantToRead = widget.allBooks
        .where((b) => b.status == ReadingStatus.wantToRead || b.status == ReadingStatus.toRead)
        .length;

    // 6. Average score (only rated books, not treating unrated as 0)
    final ratedBooks = widget.allBooks.where((b) => (b.rating != null && b.rating! > 0) || (b.avgRating != null && b.avgRating! > 0)).toList();
    double avgScore = 0.0;
    if (ratedBooks.isNotEmpty) {
      final sum = ratedBooks.fold<double>(0.0, (acc, b) => acc + (b.rating ?? b.avgRating ?? 0.0));
      avgScore = sum / ratedBooks.length;
    }

    // 7. Genre count & distribution
    final Map<String, int> genreCounts = {};
    for (final b in widget.allBooks) {
      final g = b.genre.trim().isNotEmpty ? b.genre.trim() : 'Fiction';
      genreCounts[g] = (genreCounts[g] ?? 0) + 1;
    }
    final int distinctGenres = genreCounts.length;

    // 8. Favourite genre with tie-handling
    String favouriteGenre = 'None';
    int maxGenreCount = 0;
    if (genreCounts.isNotEmpty) {
      final sortedEntries = genreCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      maxGenreCount = sortedEntries.first.value;
      final topGenres = sortedEntries.where((e) => e.value == maxGenreCount).map((e) => e.key).toList();
      favouriteGenre = topGenres.join(' & ');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 600 ? (constraints.maxWidth - 30) / 4 : (constraints.maxWidth - 10) / 2;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Primary Stats Row (Total, Read, Reading, Completion %)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildStatCard(
                  title: total.toString(),
                  subtitle: 'Total Books',
                  icon: Icons.auto_stories_rounded,
                  color: ClayColors.primaryPurple,
                  width: cardWidth,
                ),
                _buildStatCard(
                  title: completed.toString(),
                  subtitle: 'Completed',
                  icon: Icons.check_circle_outline_rounded,
                  color: ClayColors.mintDark,
                  width: cardWidth,
                ),
                _buildStatCard(
                  title: '${completionPct.toStringAsFixed(0)}%',
                  subtitle: 'Completion Rate',
                  icon: Icons.pie_chart_outline_rounded,
                  color: const Color(0xFF67B5EC),
                  width: cardWidth,
                ),
                _buildStatCard(
                  title: currentlyReading.toString(),
                  subtitle: 'Currently Reading',
                  icon: Icons.timelapse_rounded,
                  color: ClayColors.amberDark,
                  width: cardWidth,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Toggle Expand for Secondary Stats
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9E0F6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isExpanded ? 'Hide Deep Statistics ▲' : 'View Deep Bookshelf Statistics ▼',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.deepPurple,
                      ),
                    ),
                    Text(
                      '${ratedBooks.length} rated · $distinctGenres genres',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: ClayColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_isExpanded) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildStatCard(
                    title: wantToRead.toString(),
                    subtitle: 'Want to Read (TBR)',
                    icon: Icons.bookmark_border_rounded,
                    color: const Color(0xFF9C27B0),
                    width: cardWidth,
                  ),
                  _buildStatCard(
                    title: avgScore > 0 ? '${avgScore.toStringAsFixed(1)} ★' : 'N/A',
                    subtitle: 'Average Score',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFFFB300),
                    width: cardWidth,
                  ),
                  _buildStatCard(
                    title: distinctGenres.toString(),
                    subtitle: 'Distinct Genres',
                    icon: Icons.category_rounded,
                    color: const Color(0xFF009688),
                    width: cardWidth,
                  ),
                  _buildStatCard(
                    title: favouriteGenre,
                    subtitle: 'Top Genre ($maxGenreCount books)',
                    icon: Icons.favorite_rounded,
                    color: ClayColors.coral,
                    width: cardWidth,
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClayColors.clayBorder),
        boxShadow: [
          BoxShadow(
            color: ClayColors.deepPurple.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ClayColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ClayColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

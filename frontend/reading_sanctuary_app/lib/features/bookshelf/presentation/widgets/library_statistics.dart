import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LibraryStatistics extends StatelessWidget {
  final int totalBooks;
  final int totalShelves;
  final int readThisYear;

  const LibraryStatistics({
    super.key,
    required this.totalBooks,
    required this.totalShelves,
    required this.readThisYear,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 20) / 3;

        return Row(
          children: [
            _buildStatCard(
              title: totalBooks.toString(),
              subtitle: 'Total Books',
              icon: Icons.auto_stories_rounded,
              color: const Color(0xFF8C7CD6),
              width: itemWidth,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              title: totalShelves.toString(),
              subtitle: 'Bookshelves',
              icon: Icons.shelves,
              color: const Color(0xFFD4AF37),
              width: itemWidth,
            ),
            const SizedBox(width: 10),
            _buildStatCard(
              title: readThisYear.toString(),
              subtitle: 'Read This Year',
              icon: Icons.emoji_events_rounded,
              color: const Color(0xFF2E9E67),
              width: itemWidth,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBCE)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Text(
                title,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D234A),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7A6E82),
            ),
          ),
        ],
      ),
    );
  }
}

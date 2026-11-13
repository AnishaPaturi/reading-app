import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/author_analytics.dart';

class AuthorAnalyticsCard extends StatelessWidget {
  final AuthorAnalyticsResponse authorData;

  const AuthorAnalyticsCard({
    super.key,
    required this.authorData,
  });

  @override
  Widget build(BuildContext context) {
    final topAuthors = authorData.topAuthors;

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Authors',
                style: GoogleFonts.inter(
                  color: ClayColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                '${authorData.totalAuthors} total authors',
                style: GoogleFonts.inter(
                  color: ClayColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (topAuthors.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No author data available yet.',
                  style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            Column(
              children: List.generate(topAuthors.length, (i) {
                final author = topAuthors[i];
                final isTop3 = i < 3;
                final badgeColor = i == 0
                    ? ClayColors.amber // Gold
                    : (i == 1
                        ? const Color(0xFF9E8DE5) // Silver/Lavender
                        : (i == 2
                            ? ClayColors.coral // Bronze/Coral
                            : ClayColors.textMuted));

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isTop3 ? badgeColor.withValues(alpha: 0.35) : const Color(0xFFDDD2F5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${i + 1}',
                          style: GoogleFonts.inter(
                            color: badgeColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          author.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: ClayColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFDDD2F5)),
                        ),
                        child: Text(
                          '${author.completedCount} / ${author.bookCount} completed',
                          style: GoogleFonts.inter(
                            color: ClayColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

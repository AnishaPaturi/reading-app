import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.walnut),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                'Top Authors',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${authorData.totalAuthors} total authors',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLightSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (topAuthors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No author data available yet.',
                  style: TextStyle(color: AppColors.textLightSecondary),
                ),
              ),
            )
          else
            Column(
              children: List.generate(topAuthors.length, (i) {
                final author = topAuthors[i];
                final isTop3 = i < 3;
                final badgeColor = i == 0
                    ? const Color(0xFFE6A23C) // Gold
                    : (i == 1 ? const Color(0xFFC0C0C0) // Silver
                        : (i == 2 ? const Color(0xFFCD7F32) // Bronze
                            : AppColors.textLightSecondary));

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isTop3 ? badgeColor.withOpacity(0.3) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${i + 1}',
                          style: TextStyle(
                            color: badgeColor,
                            fontWeight: FontWeight.bold,
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
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${author.completedCount} / ${author.bookCount} completed',
                          style: const TextStyle(
                            color: AppColors.textLightSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
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

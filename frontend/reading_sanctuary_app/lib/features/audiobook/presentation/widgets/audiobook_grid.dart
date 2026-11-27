import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/audiobook.dart';
import '../../data/models/playback_progress.dart';
import 'audiobook_cover.dart';

class AudiobookGridCard extends StatelessWidget {
  final Audiobook audiobook;
  final PlaybackProgress? progress;
  final VoidCallback onTap;

  const AudiobookGridCard({
    super.key,
    required this.audiobook,
    this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    final posMs = progress?.positionMs ?? 0;
    final totalMs = audiobook.totalDurationMs;
    final ratio = totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : AppColors.parchment,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: AudiobookCover(
                  coverPath: audiobook.coverPath,
                  title: audiobook.title,
                  author: audiobook.author,
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: 8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              audiobook.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.ivory : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              audiobook.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? AppColors.gold.withValues(alpha: 0.8) : AppColors.brown,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 3,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

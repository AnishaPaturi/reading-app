import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/audiobook.dart';
import '../../data/models/playback_progress.dart';
import '../../utils/audiobook_duration_utils.dart';
import 'audiobook_cover.dart';

class AudiobookListTile extends StatelessWidget {
  final Audiobook audiobook;
  final PlaybackProgress? progress;
  final VoidCallback onTap;
  final VoidCallback? onMoreOptions;

  const AudiobookListTile({
    super.key,
    required this.audiobook,
    this.progress,
    required this.onTap,
    this.onMoreOptions,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.card : AppColors.parchment,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            AudiobookCover(
              coverPath: audiobook.coverPath,
              title: audiobook.title,
              author: audiobook.author,
              width: 54,
              height: 54,
              borderRadius: 8,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    audiobook.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
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
                      fontSize: 12,
                      color: isDark ? AppColors.gold.withOpacity(0.8) : AppColors.brown,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 4,
                            backgroundColor: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AudiobookDurationUtils.formatDurationHuman(
                          Duration(milliseconds: audiobook.totalDurationMs),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onMoreOptions != null)
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey),
                onPressed: onMoreOptions,
              ),
          ],
        ),
      ),
    );
  }
}

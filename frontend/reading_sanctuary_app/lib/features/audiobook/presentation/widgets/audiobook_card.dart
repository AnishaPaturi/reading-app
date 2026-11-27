import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/audiobook.dart';
import '../../data/models/playback_progress.dart';
import 'audiobook_cover.dart';

class AudiobookCard extends ConsumerWidget {
  final Audiobook audiobook;
  final PlaybackProgress? progress;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onDelete;
  final double width;

  const AudiobookCard({
    super.key,
    required this.audiobook,
    this.progress,
    required this.onTap,
    this.onPlay,
    this.onDelete,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posMs = progress?.positionMs ?? 0;
    final totalMs = audiobook.totalDurationMs;
    final ratio = totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final percentage = (ratio * 100).round();

    String progressLabel;
    if (audiobook.status == AudiobookStatus.completed) {
      progressLabel = 'Completed';
    } else if (audiobook.status == AudiobookStatus.current && posMs > 0) {
      progressLabel = '$percentage% completed';
    } else {
      progressLabel = 'Not started';
    }

    final authorText = audiobook.author.trim().isNotEmpty
        ? audiobook.author.trim()
        : 'Unknown Author';

    final titleText = audiobook.title.trim().isNotEmpty
        ? audiobook.title.trim()
        : 'Untitled Audiobook';

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: ClayColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ClayColors.clayBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: ClayColors.deepPurple.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cover artwork
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: AudiobookCover(
                        coverPath: audiobook.coverPath,
                        title: titleText,
                        author: authorText,
                        width: width > 20 ? width - 20 : 120,
                        height: width > 20 ? width - 20 : 120,
                        borderRadius: 12,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 140),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (val) {
                            if (val == 'details') onTap();
                            if (val == 'play' && onPlay != null) onPlay!();
                            if (val == 'delete' && onDelete != null) onDelete!();
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text('Details'),
                                ],
                              ),
                            ),
                            if (onPlay != null)
                              const PopupMenuItem(
                                value: 'play',
                                child: Row(
                                  children: [
                                    Icon(Icons.play_circle_outline_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Play'),
                                  ],
                                ),
                              ),
                            if (onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                    SizedBox(width: 8),
                                    Text('Remove', style: TextStyle(color: Colors.redAccent)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ClayColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),

                // Author
                Text(
                  authorText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: ClayColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 4,
                    backgroundColor: ClayColors.softLilac.withValues(alpha: 0.35),
                    valueColor: const AlwaysStoppedAnimation<Color>(ClayColors.primaryPurple),
                  ),
                ),
                const SizedBox(height: 4),

                // Progress Percentage
                Text(
                  progressLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: audiobook.status == AudiobookStatus.completed
                        ? const Color(0xFF43A047)
                        : (audiobook.status == AudiobookStatus.current
                            ? ClayColors.primaryPurple
                            : ClayColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

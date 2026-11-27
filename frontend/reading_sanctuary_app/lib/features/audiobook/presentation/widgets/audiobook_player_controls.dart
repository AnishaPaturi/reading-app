import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';

class AudiobookPlayerControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool hasPrevious;
  final bool hasNext;
  final double playbackSpeed;
  final bool silenceSkipping;
  final bool volumeBoost;
  final bool isSleepTimerActive;
  final Duration? sleepTimerRemaining;
  final Color? accentColor;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind;
  final VoidCallback onFastForward;
  final VoidCallback onPreviousTrack;
  final VoidCallback onNextTrack;
  final VoidCallback onSpeedPressed;
  final VoidCallback onChaptersPressed;
  final VoidCallback onSleepTimerPressed;
  final VoidCallback onBookmarkPressed;
  final ValueChanged<bool>? onSilenceSkippingToggled;
  final ValueChanged<bool>? onVolumeBoostToggled;

  const AudiobookPlayerControls({
    super.key,
    required this.isPlaying,
    this.isLoading = false,
    this.hasPrevious = true,
    this.hasNext = true,
    required this.playbackSpeed,
    this.silenceSkipping = false,
    this.volumeBoost = false,
    this.isSleepTimerActive = false,
    this.sleepTimerRemaining,
    this.accentColor,
    required this.onPlayPause,
    required this.onRewind,
    required this.onFastForward,
    required this.onPreviousTrack,
    required this.onNextTrack,
    required this.onSpeedPressed,
    required this.onChaptersPressed,
    required this.onSleepTimerPressed,
    required this.onBookmarkPressed,
    this.onSilenceSkippingToggled,
    this.onVolumeBoostToggled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = accentColor ?? (isDark ? AppColors.gold : AppColors.brown);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Transport Row: -15s | Prev | PLAY/PAUSE | Next | +30s
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10_rounded, size: 30),
              tooltip: 'Rewind 15 seconds',
              color: isDark ? AppColors.ivory : AppColors.textDark,
              onPressed: onRewind,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.skip_previous_rounded, size: 34),
              tooltip: 'Previous Track',
              color: hasPrevious
                  ? (isDark ? AppColors.ivory : AppColors.textDark)
                  : Colors.grey.withValues(alpha: 0.4),
              onPressed: hasPrevious ? onPreviousTrack : null,
            ),
            const SizedBox(width: 14),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPlayPause,
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: isDark ? AppColors.espresso : AppColors.ivory,
                            ),
                          )
                        : Icon(
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 42,
                            color: isDark ? AppColors.espresso : AppColors.ivory,
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            IconButton(
              icon: const Icon(Icons.skip_next_rounded, size: 34),
              tooltip: 'Next Track',
              color: hasNext
                  ? (isDark ? AppColors.ivory : AppColors.textDark)
                  : Colors.grey.withValues(alpha: 0.4),
              onPressed: hasNext ? onNextTrack : null,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.forward_30_rounded, size: 30),
              tooltip: 'Forward 30 seconds',
              color: isDark ? AppColors.ivory : AppColors.textDark,
              onPressed: onFastForward,
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Action icons row: Speed | Chapters | Sleep Timer | Bookmark
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Playback Speed
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                backgroundColor: primary.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: onSpeedPressed,
              child: Text(
                '${playbackSpeed}x',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),

            // Chapters
            IconButton(
              icon: const Icon(Icons.format_list_bulleted_rounded),
              tooltip: 'Chapters',
              color: isDark ? AppColors.ivory : AppColors.textDark,
              onPressed: onChaptersPressed,
            ),

            // Sleep Timer
            IconButton(
              icon: Badge(
                isLabelVisible: isSleepTimerActive,
                backgroundColor: primary,
                label: sleepTimerRemaining != null
                    ? Text('${sleepTimerRemaining!.inMinutes}m')
                    : const Icon(Icons.check, size: 8),
                child: Icon(
                  Icons.bedtime_rounded,
                  color: isSleepTimerActive ? primary : (isDark ? AppColors.ivory : AppColors.textDark),
                ),
              ),
              tooltip: 'Sleep Timer',
              onPressed: onSleepTimerPressed,
            ),

            // Bookmark
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined),
              tooltip: 'Add Bookmark',
              color: isDark ? AppColors.ivory : AppColors.textDark,
              onPressed: onBookmarkPressed,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Audio enhancement toggles: Silence Skip & Volume Boost
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilterChip(
              selected: silenceSkipping,
              label: Text(
                'Skip Silence',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: silenceSkipping
                      ? (isDark ? AppColors.espresso : AppColors.ivory)
                      : (isDark ? AppColors.ivory : AppColors.textDark),
                ),
              ),
              selectedColor: primary,
              checkmarkColor: isDark ? AppColors.espresso : AppColors.ivory,
              onSelected: (val) => onSilenceSkippingToggled?.call(val),
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: volumeBoost,
              label: Text(
                'Volume Boost',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: volumeBoost
                      ? (isDark ? AppColors.espresso : AppColors.ivory)
                      : (isDark ? AppColors.ivory : AppColors.textDark),
                ),
              ),
              selectedColor: primary,
              checkmarkColor: isDark ? AppColors.espresso : AppColors.ivory,
              onSelected: (val) => onVolumeBoostToggled?.call(val),
            ),
          ],
        ),
      ],
    );
  }
}

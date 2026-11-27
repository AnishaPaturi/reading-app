import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../services/audiobook_sleep_timer_service.dart';
import '../../utils/audiobook_duration_utils.dart';

class SleepTimerSheet extends StatefulWidget {
  final AudiobookSleepTimerService sleepTimer;
  final VoidCallback onTimerStarted;

  const SleepTimerSheet({
    super.key,
    required this.sleepTimer,
    required this.onTimerStarted,
  });

  @override
  State<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends State<SleepTimerSheet> {
  bool _fadeOut = true;
  bool _shakeToExtend = true;
  bool _nightAppearance = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    final isActive = widget.sleepTimer.isActive;
    final remaining = widget.sleepTimer.remaining;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.espresso : AppColors.ivory,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sleep Timer',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.ivory : AppColors.textDark,
                ),
              ),
              if (isActive)
                TextButton.icon(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Cancel'),
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  onPressed: () {
                    widget.sleepTimer.cancel();
                    setState(() {});
                  },
                ),
            ],
          ),

          if (isActive && remaining != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bedtime_rounded, color: primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Time remaining:',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.ivory : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    AudiobookDurationUtils.formatDuration(remaining),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.sleepTimer.extend(amount: const Duration(minutes: 5));
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary),
                    ),
                    child: const Text('+5 min'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.sleepTimer.extend(amount: const Duration(minutes: 15));
                      setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary),
                    ),
                    child: const Text('+15 min'),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          Text(
            'Duration',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDurationChip(15, primary, isDark),
              _buildDurationChip(30, primary, isDark),
              _buildDurationChip(45, primary, isDark),
              _buildDurationChip(60, primary, isDark),
            ],
          ),

          const SizedBox(height: 16),
          Text(
            'Stops at boundary',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.bookmark_border_rounded, size: 18),
                  label: const Text('End of chapter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.ivory : AppColors.textDark,
                  ),
                  onPressed: () {
                    widget.sleepTimer.startChapterEndTimer(enableNightAppearance: _nightAppearance);
                    widget.onTimerStarted();
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const Text('End of track'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.ivory : AppColors.textDark,
                  ),
                  onPressed: () {
                    widget.sleepTimer.startTrackEndTimer(enableNightAppearance: _nightAppearance);
                    widget.onTimerStarted();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Settings: Fade-out, Shake, Night Appearance
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Fade-out volume smoothly',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? AppColors.ivory : AppColors.textDark,
              ),
            ),
            subtitle: Text(
              'Lowers volume over final 20s',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
            ),
            value: _fadeOut,
            activeThumbColor: primary,
            onChanged: (val) => setState(() => _fadeOut = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Shake to extend',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? AppColors.ivory : AppColors.textDark,
              ),
            ),
            subtitle: Text(
              'Shake phone to add 5 minutes',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
            ),
            value: _shakeToExtend,
            activeThumbColor: primary,
            onChanged: (val) => setState(() => _shakeToExtend = val),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Night appearance',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? AppColors.ivory : AppColors.textDark,
              ),
            ),
            subtitle: Text(
              'Ultra-dim warm player interface',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
            ),
            value: _nightAppearance,
            activeThumbColor: primary,
            onChanged: (val) => setState(() => _nightAppearance = val),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChip(int minutes, Color primary, bool isDark) {
    return ActionChip(
      label: Text('$minutes min'),
      labelStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.ivory : AppColors.textDark,
      ),
      backgroundColor: primary.withValues(alpha: 0.12),
      onPressed: () {
        widget.sleepTimer.startDurationTimer(
          Duration(minutes: minutes),
          fadeOut: _fadeOut,
          enableShake: _shakeToExtend,
          enableNightAppearance: _nightAppearance,
        );
        widget.onTimerStarted();
        Navigator.pop(context);
      },
    );
  }
}

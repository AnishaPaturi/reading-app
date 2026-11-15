import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/audio_chapter.dart';
import '../../utils/audiobook_duration_utils.dart';

class ChapterListSheet extends StatelessWidget {
  final List<AudioChapter> chapters;
  final int activeChapterIndex;
  final bool stopAtChapterEnd;
  final ValueChanged<int> onSelectChapter;
  final ValueChanged<bool> onToggleStopAtChapterEnd;

  const ChapterListSheet({
    super.key,
    required this.chapters,
    required this.activeChapterIndex,
    required this.stopAtChapterEnd,
    required this.onSelectChapter,
    required this.onToggleStopAtChapterEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.espresso : AppColors.ivory,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chapters (${chapters.length})',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.ivory : AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  Text(
                    'Stop at chapter end',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.ivory.withOpacity(0.8) : AppColors.textDark.withOpacity(0.8),
                    ),
                  ),
                  Switch(
                    value: stopAtChapterEnd,
                    activeColor: primary,
                    onChanged: onToggleStopAtChapterEnd,
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          if (chapters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No chapter markers detected.\nTracks will play in sequential order.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final ch = chapters[index];
                  final isActive = index == activeChapterIndex;
                  final duration = ch.end - ch.start;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isActive ? primary : Colors.grey.withOpacity(0.15),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? (isDark ? AppColors.espresso : AppColors.ivory)
                              : (isDark ? AppColors.ivory : AppColors.textDark),
                        ),
                      ),
                    ),
                    title: Text(
                      ch.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive ? primary : (isDark ? AppColors.ivory : AppColors.textDark),
                      ),
                    ),
                    subtitle: Text(
                      '${AudiobookDurationUtils.formatDuration(ch.start)} - ${AudiobookDurationUtils.formatDuration(ch.end)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    trailing: Text(
                      AudiobookDurationUtils.formatDuration(duration),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      onSelectChapter(index);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

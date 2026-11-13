import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/audio_chapter.dart';

class AudiobookChapterListSheet extends StatelessWidget {
  final List<AudioChapter> chapters;
  final int currentChapterIndex;
  final ValueChanged<int> onChapterSelected;

  const AudiobookChapterListSheet({
    super.key,
    required this.chapters,
    required this.currentChapterIndex,
    required this.onChapterSelected,
  });

  static void show(
    BuildContext context, {
    required List<AudioChapter> chapters,
    required int currentChapterIndex,
    required ValueChanged<int> onChapterSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.88,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: AudiobookChapterListSheet(
            chapters: chapters,
            currentChapterIndex: currentChapterIndex,
            onChapterSelected: onChapterSelected,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chapters (${chapters.length})',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ClayColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ClayColors.deepPurple),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEDE5F8), height: 1),
          if (chapters.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No chapter metadata found for this track',
                  style: GoogleFonts.inter(
                    color: ClayColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: chapters.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  final isCurrent = index == currentChapterIndex;

                  return Material(
                    color: isCurrent ? const Color(0xFFFAF7FE) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isCurrent ? const BorderSide(color: Color(0xFFDDD2F5)) : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: isCurrent
                          ? const Icon(Icons.equalizer_rounded, color: ClayColors.deepPurple)
                          : Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE5F8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.inter(
                                  color: ClayColors.deepPurple,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                      title: Text(
                        chapter.title,
                        style: GoogleFonts.inter(
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent ? ClayColors.deepPurple : ClayColors.textDark,
                          fontSize: 14,
                        ),
                      ),
                      trailing: Text(
                        _formatDuration(chapter.start),
                        style: GoogleFonts.inter(
                          color: ClayColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        onChapterSelected(index);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

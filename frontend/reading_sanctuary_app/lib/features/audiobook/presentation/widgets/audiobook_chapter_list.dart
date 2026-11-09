import 'package:flutter/material.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => AudiobookChapterListSheet(
          chapters: chapters,
          currentChapterIndex: currentChapterIndex,
          onChapterSelected: onChapterSelected,
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
    final theme = Theme.of(context);

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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (chapters.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No chapter metadata found for this track',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: chapters.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  final isCurrent = index == currentChapterIndex;

                  return ListTile(
                    selected: isCurrent,
                    selectedTileColor:
                        theme.colorScheme.primaryContainer.withAlpha(70),
                    leading: isCurrent
                        ? Icon(Icons.equalizer_rounded,
                            color: theme.colorScheme.primary)
                        : Text(
                            '${index + 1}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                    title: Text(
                      chapter.title,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: Text(
                      _formatDuration(chapter.start),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () {
                      onChapterSelected(index);
                      Navigator.pop(context);
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

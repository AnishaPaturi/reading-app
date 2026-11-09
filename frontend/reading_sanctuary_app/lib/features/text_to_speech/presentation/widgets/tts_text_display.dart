import 'package:flutter/material.dart';

class TtsTextDisplay extends StatelessWidget {
  final String text;
  final String? spokenWord;
  final int currentChunk;
  final int totalChunks;
  final int currentChapter;

  const TtsTextDisplay({
    super.key,
    required this.text,
    this.spokenWord,
    required this.currentChunk,
    required this.totalChunks,
    required this.currentChapter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chapter $currentChapter',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                totalChunks > 0
                    ? 'Paragraph ${currentChunk + 1} of $totalChunks'
                    : 'Loading...',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (text.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No text available in this segment',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            _buildHighlightedText(context, text, spokenWord),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String fullText,
    String? word,
  ) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      height: 1.6,
      fontSize: 16,
    );

    if (word == null || word.trim().isEmpty) {
      return Text(fullText, style: textStyle);
    }

    final lowerText = fullText.toLowerCase();
    final lowerWord = word.toLowerCase();
    final index = lowerText.indexOf(lowerWord);

    if (index == -1) {
      return Text(fullText, style: textStyle);
    }

    final before = fullText.substring(0, index);
    final match = fullText.substring(index, index + word.length);
    final after = fullText.substring(index + word.length);

    return RichText(
      text: TextSpan(
        style: textStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: textStyle?.copyWith(
              backgroundColor: theme.colorScheme.primaryContainer,
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

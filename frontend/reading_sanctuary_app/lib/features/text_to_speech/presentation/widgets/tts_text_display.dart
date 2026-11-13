import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

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
    return ClayCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7FE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDD2F5)),
                ),
                child: Text(
                  'Chapter $currentChapter',
                  style: GoogleFonts.inter(
                    color: ClayColors.deepPurple,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                totalChunks > 0
                    ? 'Paragraph ${currentChunk + 1} of $totalChunks'
                    : 'Loading...',
                style: GoogleFonts.inter(
                  color: ClayColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (text.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No text available for this chapter',
                  style: GoogleFonts.inter(
                    color: ClayColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            _buildHighlightedText(context),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(BuildContext context) {
    if (spokenWord == null || spokenWord!.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16,
          height: 1.6,
          color: ClayColors.textDark,
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerWord = spokenWord!.toLowerCase().trim();
    final matchIndex = lowerText.indexOf(lowerWord);

    if (matchIndex == -1) {
      return Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16,
          height: 1.6,
          color: ClayColors.textDark,
        ),
      );
    }

    final before = text.substring(0, matchIndex);
    final match = text.substring(matchIndex, matchIndex + spokenWord!.length);
    final after = text.substring(matchIndex + spokenWord!.length);

    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 16,
          height: 1.6,
          color: ClayColors.textDark,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: const TextStyle(
              backgroundColor: Color(0xFFE8E0FB),
              color: ClayColors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

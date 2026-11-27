import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/datasources/audiobook_local_datasource.dart';
import '../../data/models/audiobook.dart';
import 'audiobook_card.dart';

class AudiobookSection extends StatelessWidget {
  final String title;
  final List<Audiobook> audiobooks;
  final AudiobookLocalDatasource localDb;
  final void Function(Audiobook) onBookTap;
  final void Function(Audiobook)? onBookPlay;
  final void Function(Audiobook)? onBookDelete;
  final Color? badgeColor;

  const AudiobookSection({
    super.key,
    required this.title,
    required this.audiobooks,
    required this.localDb,
    required this.onBookTap,
    this.onBookPlay,
    this.onBookDelete,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (audiobooks.isEmpty) {
      return const SizedBox.shrink();
    }

    final accent = badgeColor ?? ClayColors.primaryPurple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Row(
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${audiobooks.length}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Horizontal List of Cards
        SizedBox(
          height: 250,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: audiobooks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final book = audiobooks[index];
              final progress = localDb.getProgress(book.id);
              return AudiobookCard(
                audiobook: book,
                progress: progress,
                width: 148,
                onTap: () => onBookTap(book),
                onPlay: onBookPlay != null ? () => onBookPlay!(book) : null,
                onDelete: onBookDelete != null ? () => onBookDelete!(book) : null,
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../shared/models/book.dart';
import '../../../shared/services/providers.dart';
import '../../../shared/utils/book_file_navigation.dart';
import '../../bookshelf/presentation/widgets/book_delete_dialog.dart';
import '../../dnf/screens/dnf_cinematic_screen.dart';
import '../theme/bookshelf_theme.dart';

class BookPreviewSheet extends ConsumerWidget {
  final Book book;

  const BookPreviewSheet({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = BookshelfTheme.paletteForId(book.id);

    return SingleChildScrollView(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF7F3FD),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: BookshelfTheme.searchHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Row with Book Spine & Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upright Front Book Cover
                SizedBox(
                  width: 80,
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BookCover(
                      book: book,
                      borderRadius: 10,
                      fit: BoxFit.cover,
                      elevation: 4,
                      aspectRatio: null,
                    ),
                  ),
                ),

                const SizedBox(width: 18),

                // Book Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E1A48),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'by ${book.author}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7A6894),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Badges row
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _Badge(
                            text: book.genre,
                            color: palette.base.withValues(alpha: 0.2),
                            textColor: const Color(0xFF4C3364),
                          ),
                          _Badge(
                            text: '${book.pages} pages',
                            color: BookshelfTheme.searchPill,
                            textColor: const Color(0xFF5A4474),
                          ),
                          if (book.rating != null)
                            _Badge(
                              icon: Icons.star_rounded,
                              text: '${book.rating}',
                              color: const Color(0xFFFDE9B8),
                              textColor: const Color(0xFF8C6418),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Move to Deleted Action Button before Reading Progress
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final confirmed = await showBookDeleteDialog(context, book);
                  if (!confirmed || !context.mounted) return;

                  try {
                    await ref.read(booksProvider.notifier).moveToDeleted(book.id);

                    if (!context.mounted) return;

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${book.title}" moved to Deleted'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        action: SnackBarAction(
                          label: 'Undo',
                          textColor: BookshelfTheme.purpleAccent,
                          onPressed: () {
                            ref.read(booksProvider.notifier).restoreBook(book.id);
                          },
                        ),
                      ),
                    );
                  } catch (error) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not delete book: $error'),
                        backgroundColor: const Color(0xFF8B2635),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF8B2635), size: 18),
                label: Text(
                  'Move to Deleted',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF8B2635),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Reading Progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reading Progress',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B5885),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        '${(book.progress * 100).round()}% (${book.currentPage}/${book.pages} p.)',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: BookshelfTheme.purpleAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: book.progress,
                    minHeight: 8,
                    backgroundColor: BookshelfTheme.searchPill,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      BookshelfTheme.purpleAccent,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Status Quick Selector
          Text(
            'Change Status',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B5885),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final status in ReadingStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        status.label,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: book.status == status
                              ? Colors.white
                              : const Color(0xFF4C366B),
                        ),
                      ),
                      selected: book.status == status,
                      selectedColor: BookshelfTheme.purpleAccent,
                      backgroundColor: BookshelfTheme.searchPill,
                      onSelected: (selected) {
                        if (selected) {
                          if (status == ReadingStatus.dnf) {
                            Navigator.of(context).pop();
                            DnfCinematicScreen.trigger(
                              context,
                              book: book,
                              previousStatus: book.status,
                            );
                            return;
                          }
                          ref.read(booksProvider.notifier).setStatus(book.id, status);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons: Open Book Details / Read
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/book/${book.id}');
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: BookshelfTheme.purpleAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Details',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BookshelfTheme.purpleAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (book.files.isNotEmpty) {
                      openBookDocument(context, book);
                    } else {
                      context.push('/book/${book.id}');
                    }
                  },
                  icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                  label: Text(
                    book.progress > 0 && book.currentPage > 0
                        ? 'Continue (p. ${book.currentPage})'
                        : 'Read Now',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BookshelfTheme.purpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const _Badge({
    required this.text,
    required this.color,
    required this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

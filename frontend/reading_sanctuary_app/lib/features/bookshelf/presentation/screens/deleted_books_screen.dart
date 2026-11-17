import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/book_cover.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';

class DeletedBooksScreen extends ConsumerWidget {
  const DeletedBooksScreen({super.key});

  Future<void> _restoreBook(BuildContext context, WidgetRef ref, Book book) async {
    try {
      await ref.read(booksProvider.notifier).restoreBook(book.id);
      if (context.mounted) {
        final target = book.previousStatus?.label ?? 'Library';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${book.title}" restored to $target'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore book: $e'),
            backgroundColor: const Color(0xFF8B2635),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmPermanentDelete(BuildContext context, WidgetRef ref, Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE4DAD1)),
        ),
        title: Text(
          'Delete Forever?',
          style: GoogleFonts.cinzel(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2C221E),
          ),
        ),
        content: Text(
          'Are you sure you want to permanently delete "${book.title}" and all its reading data and files? This cannot be undone.',
          style: GoogleFonts.inter(
            color: const Color(0xFF6B584C),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B584C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B2635),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Delete Forever',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(booksProvider.notifier).permanentlyDeleteBook(book.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${book.title}" was permanently removed.'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to permanently delete: $e'),
              backgroundColor: const Color(0xFF8B2635),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletedAsync = ref.watch(deletedBooksProvider);
    final isWide = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
          tooltip: 'Back to Library',
          onPressed: () => context.canPop() ? context.pop() : context.go('/library'),
        ),
        title: Text(
          'Deleted Books',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ClayColors.textDark,
          ),
        ),
      ),
      body: deletedAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ClayColors.deepPurple),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: ClayColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'Could not load deleted books',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => ref.invalidate(deletedBooksProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EAE1),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDED3C6)),
                      ),
                      child: const Icon(
                        Icons.auto_stories_outlined,
                        size: 38,
                        color: Color(0xFF8C7D73),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'The Forgotten Shelf is Empty',
                      style: GoogleFonts.cinzel(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Books you remove from your library will rest here until you choose to restore or permanently erase them.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: ClayColors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Header description
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 32 : 20,
                  16,
                  isWide ? 32 : 20,
                  16,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'THE FORGOTTEN SHELF',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: ClayColors.primaryPurple,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.archive_outlined, size: 14, color: ClayColors.amber),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Books Resting in Deleted',
                        style: GoogleFonts.cinzel(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: ClayColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Restore your books to return them to their original shelves with all progress intact, or delete forever.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: ClayColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Grid / List of Deleted Books
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 32 : 18,
                  0,
                  isWide ? 32 : 18,
                  32,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = books[index];
                      return _DeletedBookCard(
                        book: book,
                        onRestore: () => _restoreBook(context, ref, book),
                        onPermanentDelete: () => _confirmPermanentDelete(context, ref, book),
                      );
                    },
                    childCount: books.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeletedBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  const _DeletedBookCard({
    required this.book,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  @override
  Widget build(BuildContext context) {
    final prevStatusLabel = book.previousStatus?.label ?? 'Want to Read';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2), // Warm Parchment
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DDD3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover
          SizedBox(
            width: 72,
            height: 108,
            child: BookCover(
              book: book,
              borderRadius: 8,
              elevation: 4,
            ),
          ),

          const SizedBox(width: 16),

          // Details & Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C221E),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF75675F),
                  ),
                ),

                const SizedBox(height: 6),

                // Previous status chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE8DE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDED3C6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 12, color: Color(0xFF8C7D73)),
                      const SizedBox(width: 4),
                      Text(
                        'Previously: $prevStatusLabel',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B584C),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onRestore,
                      icon: const Icon(Icons.restore_rounded, size: 16),
                      label: const Text('Restore'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5B3E8C),
                        side: const BorderSide(color: Color(0xFFB5A4D0)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onPermanentDelete,
                      icon: const Icon(Icons.delete_forever_rounded, size: 16, color: Color(0xFF8B2635)),
                      label: Text(
                        'Delete Forever',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF8B2635),
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

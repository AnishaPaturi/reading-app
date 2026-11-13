import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../../dnf/screens/dnf_cinematic_screen.dart';
import '../../../library/theme/bookshelf_theme.dart';
import '../../application/quotes_highlights_provider.dart';

class ReadingTrackerScreen extends ConsumerWidget {
  final String title;
  final ReadingStatus? statusFilter;
  final bool isHighlightsMode;
  final bool isQuotesMode;

  const ReadingTrackerScreen({
    super.key,
    required this.title,
    this.statusFilter,
    this.isHighlightsMode = false,
    this.isQuotesMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    final books = booksAsync.valueOrNull ?? [];

    final filtered = statusFilter != null
        ? books.where((b) => b.status == statusFilter).toList()
        : books;

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ClayColors.textDark,
          ),
        ),
        actions: [
          if (isHighlightsMode || isQuotesMode)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: ClayColors.deepPurple, size: 26),
              tooltip: isQuotesMode ? 'Add Quote' : 'Add Highlight',
              onPressed: () => _showAddDialog(context, ref, isQuote: isQuotesMode, books: books),
            ),
        ],
      ),
      body: SafeArea(
        child: isHighlightsMode || isQuotesMode
            ? _buildQuotesAndHighlights(context, ref, isQuotes: isQuotesMode)
            : _buildBooksList(context, filtered),
      ),
      floatingActionButton: (isHighlightsMode || isQuotesMode)
          ? FloatingActionButton.extended(
              onPressed: () => _showAddDialog(context, ref, isQuote: isQuotesMode, books: books),
              backgroundColor: ClayColors.deepPurple,
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
              label: Text(
                isQuotesMode ? 'New Quote' : 'New Highlight',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildBooksList(BuildContext context, List<Book> books) {
    if (books.isEmpty) {
      final isDnf = statusFilter == ReadingStatus.dnf;
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDnf ? Icons.local_fire_department_rounded : Icons.menu_book_rounded,
                size: 54,
                color: isDnf ? const Color(0xFFFFB74D) : ClayColors.textMuted.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                isDnf ? 'No retired books yet' : 'No books in this list yet',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: ClayColors.textDark),
              ),
              if (isDnf) ...[
                const SizedBox(height: 8),
                Text(
                  '“A book abandoned, not forgotten.”\nBooks you decide to part ways with will rest peacefully here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: ClayColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ClayPillButton(
                text: 'Browse Library',
                color: ClayColors.deepPurple,
                textColor: Colors.white,
                onTap: () => context.go('/library'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final book = books[index];
        final palette = BookshelfTheme.paletteForId(book.id);
        final pct = (book.progress * 100).round();
        final isDnf = statusFilter == ReadingStatus.dnf || book.status == ReadingStatus.dnf;

        return ClayCard(
          onTap: () => context.push('/book/${book.id}'),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClayBookMini(
                title: book.title,
                color: palette.base,
                width: 54,
                height: 74,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: ClayColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isDnf) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFECB3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Stopped at $pct%',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB78103),
                              ),
                            ),
                          ),
                          if (book.dnfDate != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE7F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                DateFormat.MMMd().format(book.dnfDate!),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF5E35B1),
                                ),
                              ),
                            ),
                          if (book.dnfReason != null && book.dnfReason!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBE9E7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                book.dnfReason!,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD84315),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Text(
                            '$pct% completed',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: ClayColors.coral,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${book.pages} pages',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ClayColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (isDnf)
                IconButton(
                  icon: const Icon(Icons.local_fire_department_rounded, size: 22, color: Color(0xFFFF9800)),
                  tooltip: 'View Retirement Ceremony',
                  onPressed: () => DnfCinematicScreen.trigger(context, book: book),
                )
              else
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFC0B5D8)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuotesAndHighlights(BuildContext context, WidgetRef ref, {required bool isQuotes}) {
    final allItems = ref.watch(quotesHighlightsProvider);
    final items = allItems.where((i) => i.isQuote == isQuotes).toList();

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isQuotes ? Icons.format_quote_rounded : Icons.highlight_rounded,
              size: 54,
              color: ClayColors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isQuotes ? 'No quotes saved yet' : 'No highlights saved yet',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: ClayColors.textMuted),
            ),
            const SizedBox(height: 8),
            Text(
              isQuotes
                  ? 'Tap "+ New Quote" to save memorable passages.'
                  : 'Tap "+ New Highlight" to capture key notes from your reads.',
              style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.text,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontStyle: isQuotes ? FontStyle.italic : FontStyle.normal,
                        color: ClayColors.textDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18, color: ClayColors.textMuted),
                    onSelected: (action) {
                      if (action == 'copy') {
                        Clipboard.setData(ClipboardData(text: item.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!'), behavior: SnackBarBehavior.floating),
                        );
                      } else if (action == 'delete') {
                        ref.read(quotesHighlightsProvider.notifier).removeItem(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Deleted successfully!'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    itemBuilder: (c) => [
                      const PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy_rounded, size: 16), SizedBox(width: 8), Text('Copy')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.source,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.primaryPurple,
                    ),
                  ),
                  if (item.chapter.isNotEmpty)
                    Text(
                      item.chapter,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ClayColors.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, {required bool isQuote, required List<Book> books}) {
    final textController = TextEditingController();
    final sourceController = TextEditingController();
    final chapterController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          isQuote ? 'Add New Quote' : 'Add New Highlight',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: ClayColors.textDark, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isQuote ? 'Enter the quote passage...' : 'Enter highlight text...',
                  filled: true,
                  fillColor: const Color(0xFFF6F3FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sourceController,
                decoration: InputDecoration(
                  hintText: 'Book title or author',
                  prefixIcon: const Icon(Icons.book_rounded, color: ClayColors.primaryPurple, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF6F3FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: chapterController,
                decoration: InputDecoration(
                  hintText: 'Chapter or page (optional)',
                  prefixIcon: const Icon(Icons.bookmark_outline_rounded, color: ClayColors.primaryPurple, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF6F3FB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              final text = textController.text.trim();
              final source = sourceController.text.trim();
              if (text.isNotEmpty) {
                ref.read(quotesHighlightsProvider.notifier).addItem(
                      text: text,
                      source: source.isNotEmpty ? source : 'Personal Collection',
                      chapter: chapterController.text.trim(),
                      isQuote: isQuote,
                    );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isQuote ? 'Quote added!' : 'Highlight added!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

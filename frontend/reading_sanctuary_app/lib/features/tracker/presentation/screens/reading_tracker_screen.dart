import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../../library/theme/bookshelf_theme.dart';

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
      ),
      body: SafeArea(
        child: isHighlightsMode || isQuotesMode
            ? _buildQuotesAndHighlights(context, books, isQuotes: isQuotesMode)
            : _buildBooksList(context, filtered),
      ),
    );
  }

  Widget _buildBooksList(BuildContext context, List<Book> books) {
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 54, color: ClayColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'No books in this shelf yet',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: ClayColors.textMuted),
            ),
            const SizedBox(height: 14),
            ClayPillButton(
              text: 'Browse Library',
              color: ClayColors.deepPurple,
              textColor: Colors.white,
              onTap: () => context.go('/library'),
            ),
          ],
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ClayColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '$pct% progress',
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
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFC0B5D8)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuotesAndHighlights(BuildContext context, List<Book> books, {required bool isQuotes}) {
    final sampleItems = [
      {
        'text': isQuotes
            ? '“Between life and death there is a library, and within that library, the shelves go on for ever.”'
            : 'She stopped talking because words felt like unnecessary baggage.',
        'source': 'The Midnight Library',
        'chapter': 'Chapter 1 · Page 12',
      },
      {
        'text': isQuotes
            ? '“You do not rise to the level of your goals. You fall to the level of your systems.”'
            : 'Habits are the compound interest of self-improvement.',
        'source': 'Atomic Habits',
        'chapter': 'Fundamentals · Page 27',
      },
      {
        'text': isQuotes
            ? '“Doing well with money has a little to do with how smart you are and a lot to do with how you behave.”'
            : 'No one is crazy. People do crazy things with money because our experiences vary.',
        'source': 'The Psychology of Money',
        'chapter': 'No One is Crazy · Page 15',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: sampleItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = sampleItems[index];
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
              Text(
                item['text']!,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontStyle: isQuotes ? FontStyle.italic : FontStyle.normal,
                  color: ClayColors.textDark,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item['source']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.primaryPurple,
                    ),
                  ),
                  Text(
                    item['chapter']!,
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
}

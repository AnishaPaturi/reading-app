import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_panel_header.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/library/theme/bookshelf_theme.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF4F0FB),
          drawer: isWide
              ? null
              : Drawer(
                  width: 220,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: ReaderSidebar(
                    width: 220,
                    activeRoute: '/home',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left 3D Reader Sidebar on Desktop/Tablet
                if (isWide) const ReaderSidebar(activeRoute: '/home'),

                // Main Reader Panel Content
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 24 : 16,
                          vertical: isWide ? 16 : 12,
                        ),
                        child: ReaderPanelHeader(
                          showMenuButton: !isWide,
                          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                      ),
                      Expanded(
                        child: booksAsync.when(
                          loading: () => const Center(
                            child: CircularProgressIndicator(color: ClayColors.primaryPurple),
                          ),
                          error: (e, _) => Center(
                            child: Text(
                              'Failed to load library',
                              style: GoogleFonts.inter(color: ClayColors.textMuted),
                            ),
                          ),
                          data: (books) => SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 24 : 16,
                              vertical: 8,
                            ),
                            child: _buildDashboardBody(
                              context,
                              contentWidth: isWide
                                  ? constraints.maxWidth - 234
                                  : constraints.maxWidth - 32,
                              books: books,
                            ),
                          ),
                        ),
                      ),

                      // Floating 3D Navigation Bar on Mobile
                      if (!isWide)
                        const ClayBottomNav(activeRoute: '/home'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardBody(
    BuildContext context, {
    required double contentWidth,
    required List<Book> books,
  }) {
    final useTwoColumns = contentWidth >= 800;

    final readingBooks = books
        .where((b) => b.status == ReadingStatus.currentlyReading)
        .toList();

    final listeningBooks = books
        .where((b) =>
            b.formats.contains(BookFormat.audiobook) &&
            (b.status == ReadingStatus.currentlyReading ||
                (b.progress > 0 && b.progress < 1.0)))
        .toList();

    final effectiveReading = readingBooks.isNotEmpty
        ? readingBooks
        : books.take(2).toList();
    final effectiveListening = listeningBooks.isNotEmpty
        ? listeningBooks
        : books.where((b) => b.formats.contains(BookFormat.audiobook)).take(2).toList();

    if (useTwoColumns) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildCurrentlyReadingSection(context, effectiveReading),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _buildCurrentlyListeningSection(context, effectiveListening),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCurrentlyReadingSection(context, effectiveReading),
        const SizedBox(height: 24),
        _buildCurrentlyListeningSection(context, effectiveListening),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCurrentlyReadingSection(BuildContext context, List<Book> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE5FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: ClayColors.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently Reading',
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: ClayColors.textDark,
                      ),
                    ),
                    Text(
                      'Pick up where you left off',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ClayColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ClayColors.peach.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ClayColors.peach, width: 1),
              ),
              child: Text(
                '${books.length} ${books.length == 1 ? 'Book' : 'Books'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4C2A1E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // List of Currently Reading Cards
        for (final book in books) ...[
          _buildReadingCard(context, book),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildReadingCard(BuildContext context, Book book) {
    final palette = BookshelfTheme.paletteForId(book.id);
    final progressPct = (book.progress > 0 ? (book.progress * 100).round() : 42);
    final totalPages = book.pages > 0 ? book.pages : 336;
    final currentPage = book.currentPage > 0
        ? book.currentPage
        : ((totalPages * progressPct) / 100).round();
    final pagesRemaining = totalPages - currentPage;
    final hoursRemaining =
        (pagesRemaining * 1.5 / 60).clamp(0.5, 24.0).toStringAsFixed(1);

    return ClayCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(
        '/reader/${book.id}/${book.id}?title=${Uri.encodeComponent(book.title)}&format=PDF',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D Mini Book Cover
              ClayBookMini(
                title: book.title,
                color: palette.base,
                width: 58,
                height: 82,
                hasHeart: book.rating != null && book.rating! >= 4.0,
              ),
              const SizedBox(width: 14),

              // Book Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: ClayColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECE5FA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            book.genre,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: ClayColors.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ClayColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Progress Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$progressPct% Completed',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: ClayColors.coral,
                          ),
                        ),
                        Text(
                          'Page $currentPage of $totalPages',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ClayColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressPct / 100.0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEDE6FA),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(ClayColors.coral),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Bar at Bottom of Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 15, color: ClayColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '$hoursRemaining hrs left',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ClayColors.textMuted,
                    ),
                  ),
                ],
              ),
              ClayPillButton(
                text: 'Continue Reading  →',
                height: 36,
                fontSize: 12.5,
                color: ClayColors.deepPurple,
                textColor: Colors.white,
                onTap: () => context.push(
                  '/reader/${book.id}/${book.id}?title=${Uri.encodeComponent(book.title)}&format=PDF',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentlyListeningSection(BuildContext context, List<Book> books) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDEEFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.headphones_rounded,
                    color: Color(0xFF4379EE),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently Listening',
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: ClayColors.textDark,
                      ),
                    ),
                    Text(
                      'Audiobooks in progress',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: ClayColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDDEEFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB9DBFA), width: 1),
              ),
              child: Text(
                '${books.length} ${books.length == 1 ? 'Audiobook' : 'Audiobooks'}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E3A8A),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // List of Currently Listening Cards
        for (final book in books) ...[
          _buildListeningCard(context, book),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildListeningCard(BuildContext context, Book book) {
    final palette = BookshelfTheme.paletteForId(book.id);
    final progressPct = (book.progress > 0 ? (book.progress * 100).round() : 35);
    const totalChapters = 14;
    final currentChapter =
        ((progressPct / 100.0) * totalChapters).clamp(1, totalChapters).round();
    final hoursRemaining =
        ((1.0 - (progressPct / 100.0)) * 9.5).clamp(0.5, 20.0).toStringAsFixed(1);

    return ClayCard(
      padding: const EdgeInsets.all(16),
      onTap: () => context.push(
        '/listen/${book.id}/${book.id}?title=${Uri.encodeComponent(book.title)}&author=${Uri.encodeComponent(book.author)}&format=MP3',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3D Mini Book Cover with Headphone indicator
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClayBookMini(
                    title: book.title,
                    color: palette.base,
                    width: 58,
                    height: 82,
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4379EE),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4379EE).withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Audiobook Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: ClayColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDEEFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Audiobook',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ClayColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Progress Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$progressPct% Listened',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4379EE),
                          ),
                        ),
                        Text(
                          'Chapter $currentChapter of $totalChapters',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ClayColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressPct / 100.0,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFDDEEFC),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Color(0xFF4379EE)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action Bar at Bottom of Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.volume_up_rounded,
                      size: 15, color: Color(0xFF4379EE)),
                  const SizedBox(width: 4),
                  Text(
                    '$hoursRemaining hrs left',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ClayColors.textMuted,
                    ),
                  ),
                ],
              ),
              ClayPillButton(
                text: 'Listen Now  ♫',
                height: 36,
                fontSize: 12.5,
                color: const Color(0xFF4379EE),
                textColor: Colors.white,
                onTap: () => context.push(
                  '/listen/${book.id}/${book.id}?title=${Uri.encodeComponent(book.title)}&author=${Uri.encodeComponent(book.author)}&format=MP3',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

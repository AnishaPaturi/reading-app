import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/hero_reading_banner.dart';
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
  late final ScrollController _mainScrollController;
  late final ScrollController _audiobookScrollController;

  @override
  void initState() {
    super.initState();
    _mainScrollController = ScrollController();
    _audiobookScrollController = ScrollController();
  }

  @override
  void dispose() {
    _mainScrollController.dispose();
    _audiobookScrollController.dispose();
    super.dispose();
  }

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
            bottom: false,
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
                          data: (books) => Scrollbar(
                            controller: _mainScrollController,
                            thumbVisibility: isWide,
                            child: SingleChildScrollView(
                              controller: _mainScrollController,
                              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                              padding: EdgeInsets.fromLTRB(
                                isWide ? 24 : 16,
                                8,
                                isWide ? 24 : 16,
                                isWide ? 24 : 20,
                              ),
                              child: _buildDashboardBody(
                                context,
                                contentWidth: isWide
                                    ? constraints.maxWidth - 234
                                    : constraints.maxWidth - 32,
                                books: books,
                                isWide: isWide,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : const SafeArea(
                  top: false,
                  child: ClayBottomNav(activeRoute: '/home'),
                ),
        );
      },
    );
  }

  Widget _buildDashboardBody(
    BuildContext context, {
    required double contentWidth,
    required List<Book> books,
    bool isWide = false,
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

    final effectiveReading = readingBooks;
    final effectiveListening = listeningBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3D Hero Banner: Personalized time-based greeting & star mascot
        const HeroReadingBanner(),
        const SizedBox(height: 20),

        if (useTwoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCurrentlyReadingSection(context, effectiveReading),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCurrentlyListeningSection(
                  context,
                  effectiveListening,
                  isWide: isWide,
                ),
              ),
            ],
          )
        else ...[
          _buildCurrentlyReadingSection(context, effectiveReading),
          const SizedBox(height: 24),
          _buildCurrentlyListeningSection(
            context,
            effectiveListening,
            isWide: isWide,
          ),
        ],
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
            Expanded(
              child: Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Currently Reading',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ClayColors.textDark,
                          ),
                        ),
                        Text(
                          'Pick up where you left off',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: ClayColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
        if (books.isEmpty)
          ClayCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_rounded, color: ClayColors.primaryPurple, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'No books currently in progress',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore your library to start reading!',
                    style: GoogleFonts.inter(fontSize: 12.5, color: ClayColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/library'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClayColors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    ),
                    child: const Text('Browse Library', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
          )
        else
          for (final book in books) ...[
            _buildReadingCard(context, book),
            const SizedBox(height: 14),
          ],
      ],
    );
  }

  Widget _buildReadingCard(BuildContext context, Book book) {
    final palette = BookshelfTheme.paletteForId(book.id);
    final progressPct = (book.progress * 100).round();
    final totalPages = book.pages > 0 ? book.pages : 100;
    final currentPage = book.currentPage > 0
        ? book.currentPage
        : ((totalPages * progressPct) / 100).round();
    final pagesRemaining = (totalPages - currentPage).clamp(0, totalPages);
    final hoursRemaining =
        (pagesRemaining * 1.5 / 60).clamp(0.1, 24.0).toStringAsFixed(1);

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
                        Flexible(
                          child: Text(
                            '$progressPct% Completed',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ClayColors.coral,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Page $currentPage of $totalPages',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ClayColors.textMuted,
                            ),
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
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: ClayColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$hoursRemaining hrs left',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ClayColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ClayPillButton(
                text: 'Continue Reading  →',
                height: 34,
                fontSize: 12,
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

  Widget _buildCurrentlyListeningSection(
    BuildContext context,
    List<Book> books, {
    bool isWide = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Currently Listening',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: ClayColors.textDark,
                          ),
                        ),
                        Text(
                          'Audiobooks in progress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: ClayColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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

        // Scrollable List of Currently Listening Audiobooks
        if (books.isEmpty)
          ClayCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.headphones_rounded, color: Color(0xFF4379EE), size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'No audiobooks currently in progress',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse audiobooks in your library to start listening!',
                    style: GoogleFonts.inter(fontSize: 12.5, color: ClayColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/library'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4379EE),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    ),
                    child: const Text('Find Audiobooks', style: TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 340,
            child: Scrollbar(
              controller: _audiobookScrollController,
              thumbVisibility: isWide,
              child: ListView.separated(
                controller: _audiobookScrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) =>
                    _buildListeningCard(context, books[index]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListeningCard(BuildContext context, Book book) {
    final palette = BookshelfTheme.paletteForId(book.id);
    final progressPct = (book.progress * 100).round();
    const totalChapters = 14;
    final currentChapter =
        ((book.progress) * totalChapters).clamp(1, totalChapters).round();
    final hoursRemaining =
        ((1.0 - book.progress) * 8.0).clamp(0.0, 20.0).toStringAsFixed(1);

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
                        Flexible(
                          child: Text(
                            '$progressPct% Listened',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4379EE),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Chapter $currentChapter of $totalChapters',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ClayColors.textMuted,
                            ),
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
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.volume_up_rounded,
                        size: 14, color: Color(0xFF4379EE)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$hoursRemaining hrs left',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ClayColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ClayPillButton(
                text: 'Listen Now  ♫',
                height: 34,
                fontSize: 12,
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

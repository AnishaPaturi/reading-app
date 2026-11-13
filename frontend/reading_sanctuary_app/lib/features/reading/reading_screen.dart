import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/library/theme/bookshelf_theme.dart';
import 'package:reading_sanctuary_app/features/library/widgets/clay_decorations.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          backgroundColor: ClayColors.background,
          drawer: isWide
              ? null
              : Drawer(
                  width: 220,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: ReaderSidebar(
                    width: 220,
                    activeRoute: '/reading',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          body: SafeArea(
            bottom: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) const ReaderSidebar(activeRoute: '/reading'),
                Expanded(
                  child: Stack(
                    children: [
                      // Sparkle Stars
                      const Positioned(
                        bottom: 90,
                        right: 20,
                        child: ClaySparkleStar(size: 32),
                      ),
                      const Positioned(
                        top: 40,
                        right: 24,
                        child: ClaySparkleStar(size: 24),
                      ),

                      booksAsync.when(
                        loading: () => const Center(
                          child: CircularProgressIndicator(color: ClayColors.primaryPurple),
                        ),
                        error: (e, _) => Center(
                          child: Text('Failed to load reading list', style: GoogleFonts.inter()),
                        ),
                        data: (books) {
                          if (books.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_stories_rounded, size: 54, color: ClayColors.primaryPurple),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No books in your reading list',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: ClayColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add books to your library to track your reading journey.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
                                    ),
                                    const SizedBox(height: 20),
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

                          final readingBooks = books
                              .where((b) => b.status == ReadingStatus.currentlyReading)
                              .toList();
                          final completedBooks = books
                              .where((b) => b.status == ReadingStatus.completed)
                              .toList();

                          final heroBook = readingBooks.isNotEmpty ? readingBooks.first : books.first;
                          final otherReading = readingBooks.isNotEmpty ? readingBooks.skip(1).toList() : <Book>[];

                          return Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: isWide,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: EdgeInsets.fromLTRB(
                                20,
                                16,
                                20,
                                isWide ? 24 : 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header (Scrolls with page content)
                                  _buildHeader(isWide),

                                  const SizedBox(height: 14),

                                  // 1. Hero Book Card (Currently Reading section)
                                  _buildHeroCard(heroBook),

                                  const SizedBox(height: 14),

                                  // Hero Action Buttons
                                  _buildHeroButtons(heroBook),

                                  const SizedBox(height: 28),

                                  // 2. Reading List
                                  Text(
                                    'Reading List',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: ClayColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildReadingList(otherReading),

                                  const SizedBox(height: 28),

                                  // 3. Recently Finished
                                  Text(
                                    'Recently Finished',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: ClayColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _buildRecentlyFinished(completedBooks),
                                ],
                              ),
                            ),
                          );
                        },
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
                  child: ClayBottomNav(activeRoute: '/reading'),
                ),
        );
      },
    );
  }

  Widget _buildHeader(bool isWide) {
    return Row(
      children: [
        if (!isWide) ...[
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: ClayColors.deepPurple, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            'Currently Reading',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ClayColors.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(Book book) {
    final progressPct = (book.progress > 0 ? (book.progress * 100).round() : 68);

    return ClayCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // 3D Standing Book in center with sparkles
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClayBookMini(
                  title: book.title,
                  color: ClayColors.deepPurple,
                  width: 90,
                  height: 125,
                  motif: const Icon(Icons.nightlight_round, color: Color(0xFFFFD460), size: 22),
                  onTap: () => context.push('/book/${book.id}'),
                ),
                const Positioned(
                  top: -6,
                  left: -14,
                  child: Icon(Icons.star_rounded, color: Color(0xFFFFD460), size: 20),
                ),
                const Positioned(
                  top: 10,
                  right: -16,
                  child: Icon(Icons.auto_awesome, color: Color(0xFFFF9E7D), size: 18),
                ),
                const Positioned(
                  bottom: 20,
                  right: -14,
                  child: Icon(Icons.star_rounded, color: Color(0xFFC7B2F0), size: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Title & Author
          Text(
            book.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ClayColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            book.author,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: ClayColors.textMuted,
            ),
          ),
          const SizedBox(height: 14),

          // Progress Bar & Percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Text(
                '$progressPct% Completed',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressPct / 100.0,
              minHeight: 8,
              backgroundColor: const Color(0xFFEADBFA),
              valueColor: const AlwaysStoppedAnimation<Color>(ClayColors.coral),
            ),
          ),
          const SizedBox(height: 10),

          // Pages & Time Left
          Builder(builder: (context) {
            final totalPages = book.pages > 0 ? book.pages : 1;
            final currentPage = book.currentPage;
            final pagesRemaining = (totalPages - currentPage).clamp(0, totalPages);
            final hoursRemaining = (pagesRemaining * 1.5 / 60).toStringAsFixed(1);

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Pages: $currentPage / $totalPages',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: ClayColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Time Left: $hoursRemaining hrs',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: ClayColors.textMuted,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeroButtons(Book book) {
    return Column(
      children: [
        // Continue Reading Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push(
                '/reader/${book.id}/${book.id}?title=${Uri.encodeComponent(book.title)}&format=PDF',
              );
            },
            icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFB28D), size: 20),
            label: Text(
              'Continue Reading  →',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // View Notes & Log Reading Buttons
        Row(
          children: [
            Expanded(
              child: ClayPillButton(
                text: 'View Notes',
                color: ClayColors.peach,
                textColor: const Color(0xFF3B2352),
                height: 40,
                onTap: () => context.push('/book/${book.id}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClayPillButton(
                text: 'Log Reading',
                color: ClayColors.lavender,
                textColor: const Color(0xFF3B2352),
                height: 40,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reading session logged!')),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadingList(List<Book> books) {
    if (books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No other books in progress.',
          style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final b = books[index];
        final palette = BookshelfTheme.paletteForId(b.id);
        final pct = (b.progress * 100).round();

        return ClayCard(
          onTap: () => context.push('/book/${b.id}'),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClayBookMini(
                title: b.title,
                color: palette.base,
                width: 52,
                height: 72,
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$pct% Read',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClayColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100.0,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFEBE0F7),
                        valueColor: const AlwaysStoppedAnimation<Color>(ClayColors.coral),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              ClayPillButton(
                text: 'Resume',
                color: ClayColors.peach,
                textColor: const Color(0xFF382352),
                height: 32,
                fontSize: 12,
                onTap: () => context.push(
                  '/reader/${b.id}/${b.id}?title=${Uri.encodeComponent(b.title)}&format=PDF',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentlyFinished(List<Book> books) {
    if (books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No completed books yet.',
          style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
        ),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final b = books[index];
          final palette = BookshelfTheme.paletteForId(b.id);

          return ClayBookMini(
            title: b.title,
            color: palette.base,
            width: 66,
            height: 92,
            hasCheck: true,
            onTap: () => context.push('/book/${b.id}'),
          );
        },
      ),
    );
  }
}

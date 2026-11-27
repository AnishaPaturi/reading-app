import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/currently_reading_carousel.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/dashboard_streak_card.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/hero_reading_banner.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_panel_header.dart';
import 'package:reading_sanctuary_app/features/home/presentation/widgets/reader_sidebar.dart';
import 'package:reading_sanctuary_app/features/library/theme/bookshelf_theme.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';
import '../../shared/utils/book_file_navigation.dart';
import '../reader/domain/reading_progress.dart';
import 'presentation/providers/home_reading_progress_provider.dart';

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
    final progressMap = ref.watch(homeProgressByFileIdProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: ClayColors.canvasBackground,
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
                            child: RefreshIndicator(
                              color: ClayColors.primaryPurple,
                              onRefresh: () async {
                                ref.invalidate(homeReadingProgressProvider);
                                ref.invalidate(booksProvider);
                                await ref.read(booksProvider.future);
                                await ref.read(homeReadingProgressProvider.future);
                              },
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
                                  progressMap: progressMap,
                                  isWide: isWide,
                                ),
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
    required Map<String, ReadingProgress> progressMap,
    bool isWide = false,
  }) {
    final useTwoColumns = contentWidth >= 800;

    final readingBooks = books
        .where((b) =>
            b.status == ReadingStatus.currentlyReading ||
            _hasActiveReadingProgress(b, progressMap))
        .toList();

    final listeningBooks = books
        .where((b) =>
            b.formats.contains(BookFormat.audiobook) &&
            (b.status == ReadingStatus.currentlyReading ||
                (b.progress > 0 && b.progress < 1.0) ||
                _hasActiveListeningProgress(b, progressMap)))
        .toList();

    final effectiveReading = readingBooks;
    final effectiveListening = listeningBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 3D Hero Banner: Personalized time-based greeting & star mascot
        const HeroReadingBanner(),
        const SizedBox(height: 20),

        // Reading Momentum, Streak & Weekly Calendar
        const DashboardStreakCard(),
        const SizedBox(height: 20),

        if (useTwoColumns)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildCurrentlyReadingSection(context, effectiveReading, progressMap),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildCurrentlyListeningSection(
                  context,
                  effectiveListening,
                  progressMap,
                  isWide: isWide,
                ),
              ),
            ],
          )
        else ...[
          _buildCurrentlyReadingSection(context, effectiveReading, progressMap),
          const SizedBox(height: 24),
          _buildCurrentlyListeningSection(
            context,
            effectiveListening,
            progressMap,
            isWide: isWide,
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCurrentlyReadingSection(
    BuildContext context,
    List<Book> books,
    Map<String, ReadingProgress> progressMap,
  ) {
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
                      color: ClayColors.pastelMutedViolet.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: ClayColors.royalLilac,
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: ClayColors.textDark,
                          ),
                        ),
                        Text(
                          'Pick up where you left off',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ClayColors.dustyPlum,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
              decoration: BoxDecoration(
                color: ClayColors.pastelMutedViolet.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ClayColors.clayBorder.withValues(alpha: 0.8), width: 1),
              ),
              child: Text(
                '${books.length} ${books.length == 1 ? 'Book' : 'Books'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.deepLavender,
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
                  const Icon(Icons.menu_book_rounded, color: ClayColors.royalLilac, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'No books currently in progress',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore your library to start reading!',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: ClayColors.dustyPlum),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/library'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClayColors.royalLilac,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'Browse Library',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          CurrentlyReadingCarousel(
            books: books,
            progressMap: progressMap,
            onContinueReading: (book, progress) => _continueReading(context, book, progress),
          ),
      ],
    );
  }

  Widget _buildCurrentlyListeningSection(
    BuildContext context,
    List<Book> books,
    Map<String, ReadingProgress> progressMap, {
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
                      color: ClayColors.sageMint.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.headphones_rounded,
                      color: Color(0xFF236B61),
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: ClayColors.textDark,
                          ),
                        ),
                        Text(
                          'Audiobooks in progress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ClayColors.dustyPlum,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
              decoration: BoxDecoration(
                color: ClayColors.sunnyButtercup.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: ClayColors.sunnyButtercup.withValues(alpha: 0.8), width: 1),
              ),
              child: Text(
                '${books.length} ${books.length == 1 ? 'Audiobook' : 'Audiobooks'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9A5B00),
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
                  const Icon(Icons.headphones_rounded, color: Color(0xFF236B61), size: 36),
                  const SizedBox(height: 10),
                  Text(
                    'No audiobooks currently in progress',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse audiobooks in your library to start listening!',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: ClayColors.dustyPlum),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/library'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClayColors.royalLilac,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      'Find Audiobooks',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
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
                    _buildListeningCard(context, books[index], progressMap),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListeningCard(
    BuildContext context,
    Book book,
    Map<String, ReadingProgress> progressMap,
  ) {
    final palette = BookshelfTheme.paletteForId(book.id);
    final audioProgress = _findListeningProgressForBook(book, progressMap);
    final double rawPct = audioProgress != null && audioProgress.progressPercentage > 0
        ? audioProgress.progressPercentage
        : (book.progress * 100.0);
    final int progressPct = rawPct.round().clamp(0, 100);
    const totalChapters = 14;
    final currentChapter =
        ((progressPct / 100.0) * totalChapters).clamp(1, totalChapters).round();
    final hoursRemaining =
        ((1.0 - (progressPct / 100.0)) * 8.0).clamp(0.0, 20.0).toStringAsFixed(1);

    return ClayCard(
      padding: const EdgeInsets.all(16),
      onTap: () {
        _continueListening(context, book, audioProgress);
      },
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
                    book: book,
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
                        color: ClayColors.sageMint,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: ClayColors.sageMint.withValues(alpha: 0.4),
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: ClayColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ClayColors.sageMint.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Audiobook',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF236B61),
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ClayColors.dustyPlum,
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
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ClayColors.creamsicleCoral,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Chapter $currentChapter of $totalChapters',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ClayColors.dustyPlum,
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
                        backgroundColor: ClayColors.pastelMutedViolet.withValues(alpha: 0.45),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(ClayColors.creamsicleCoral),
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
                        size: 14, color: ClayColors.dustyPlum),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$hoursRemaining hrs left',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: ClayColors.dustyPlum,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ClayPillButton(
                text: 'Listen Now  ♫',
                height: 36,
                fontSize: 12,
                color: ClayColors.royalLilac,
                textColor: Colors.white,
                onTap: () {
                  _continueListening(context, book, audioProgress);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _continueReading(
    BuildContext context,
    Book book,
    ReadingProgress? progress,
  ) async {
    if (progress != null) {
      final targetFile = book.files.firstWhere(
        (f) => f.id == progress.bookFileId,
        orElse: () => book.files.firstWhere(
          (f) => f.format == BookFileFormat.pdf || f.format == BookFileFormat.epub,
          orElse: () => book.files.first,
        ),
      );
      await openBookInFormat(context, book, format: targetFile.format);
    } else {
      await openBookDocument(context, book);
    }

    if (mounted) {
      ref.invalidate(homeReadingProgressProvider);
      ref.invalidate(booksProvider);
    }
  }

  Future<void> _continueListening(
    BuildContext context,
    Book book,
    ReadingProgress? progress,
  ) async {
    if (progress != null) {
      final targetFile = book.files.firstWhere(
        (f) => f.id == progress.bookFileId,
        orElse: () => book.files.firstWhere(
          (f) => f.format.isAudio,
          orElse: () => book.files.first,
        ),
      );
      await openBookInFormat(context, book, format: targetFile.format);
    } else {
      await openBookAudio(context, book);
    }

    if (mounted) {
      ref.invalidate(homeReadingProgressProvider);
      ref.invalidate(booksProvider);
    }
  }

  ReadingProgress? _findReadingProgressForBook(
    Book book,
    Map<String, ReadingProgress> progressMap,
  ) {
    ReadingProgress? best;

    for (final file in book.files) {
      if (file.format == BookFileFormat.pdf || file.format == BookFileFormat.epub) {
        final p = progressMap[file.id];
        if (p != null) {
          if (best == null) {
            best = p;
          } else {
            final bestTime = best.updatedAt ?? best.lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final pTime = p.updatedAt ?? p.lastOpenedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            if (pTime.isAfter(bestTime)) {
              best = p;
            }
          }
        }
      }
    }

    if (best != null) return best;

    // Fallback: check book.id in case a record was keyed by bookId
    if (progressMap.containsKey(book.id)) {
      return progressMap[book.id];
    }

    return null;
  }

  bool _hasActiveReadingProgress(
    Book book,
    Map<String, ReadingProgress> progressMap,
  ) {
    final progress = _findReadingProgressForBook(book, progressMap);
    if (progress == null) return false;
    final pct = progress.progressPercentage;
    final page = progress.currentPage ?? 1;
    return (pct > 0 && pct < 100) || page > 1;
  }

  ReadingProgress? _findListeningProgressForBook(
    Book book,
    Map<String, ReadingProgress> progressMap,
  ) {
    for (final file in book.files) {
      if (file.format.isAudio) {
        final p = progressMap[file.id];
        if (p != null) return p;
      }
    }
    return null;
  }

  bool _hasActiveListeningProgress(
    Book book,
    Map<String, ReadingProgress> progressMap,
  ) {
    final progress = _findListeningProgressForBook(book, progressMap);
    if (progress == null) return false;
    return (progress.progressPercentage > 0 && progress.progressPercentage < 100) ||
        (progress.audioPositionMs != null && progress.audioPositionMs! > 0);
  }
}

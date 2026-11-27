import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/audiobook.dart';
import '../providers/audiobook_library_provider.dart';
import '../providers/audiobook_providers.dart';
import '../widgets/audiobook_card.dart';
import '../widgets/audiobook_cover.dart';
import '../widgets/audiobook_empty_state.dart';
import '../widgets/audiobook_list_tile.dart';
import '../widgets/audiobook_section.dart';

class AudiobookLibraryPage extends ConsumerStatefulWidget {
  const AudiobookLibraryPage({super.key});

  @override
  ConsumerState<AudiobookLibraryPage> createState() => _AudiobookLibraryPageState();
}

class _AudiobookLibraryPageState extends ConsumerState<AudiobookLibraryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? ClayColors.softLilac : ClayColors.primaryPurple;

    final filter = ref.watch(audiobookLibraryFilterProvider);
    final filterNotifier = ref.read(audiobookLibraryFilterProvider.notifier);
    final libState = ref.watch(audiobookLibraryProvider);
    final books = ref.watch(filteredAudiobooksProvider);
    final currentBooks = ref.watch(currentAudiobooksProvider);
    final notStartedBooks = ref.watch(notStartedAudiobooksProvider);
    final completedBooks = ref.watch(completedAudiobooksProvider);
    final localDb = ref.watch(audiobookLocalDatasourceProvider);
    final resumeSuggestion = ref.watch(audiobookResumeSuggestionProvider);

    final isDefaultSectionView = filter.status == null && filter.query.trim().isEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B1527) : ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Audiobooks',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            color: isDark ? Colors.white : ClayColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'All Bookmarks',
            color: isDark ? Colors.white70 : ClayColors.deepPurple,
            onPressed: () => context.push('/audiobooks/bookmarks'),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Listening History',
            color: isDark ? Colors.white70 : ClayColors.deepPurple,
            onPressed: () => context.push('/audiobooks/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Audiobook Settings',
            color: isDark ? Colors.white70 : ClayColors.deepPurple,
            onPressed: () => context.push('/audiobooks/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ClayColors.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Import'),
        onPressed: () => context.push('/audiobooks/import'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(audiobookLibraryProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF271E38) : ClayColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : ClayColors.clayBorder,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ClayColors.deepPurple.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => filterNotifier.setQuery(val),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white : ClayColors.textDark,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search audiobooks and authors...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? Colors.white38 : ClayColors.textMuted,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: isDark ? Colors.white54 : ClayColors.textMuted,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      filterNotifier.setQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status Filter Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildStatusFilterChip(
                        label: 'All Sections',
                        isSelected: filter.status == null,
                        onSelected: () => filterNotifier.setStatus(null),
                        primary: primary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'Current (${currentBooks.length})',
                        isSelected: filter.status == AudiobookStatus.current,
                        onSelected: () => filterNotifier.setStatus(AudiobookStatus.current),
                        primary: primary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'Not started (${notStartedBooks.length})',
                        isSelected: filter.status == AudiobookStatus.notStarted,
                        onSelected: () => filterNotifier.setStatus(AudiobookStatus.notStarted),
                        primary: primary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'Completed (${completedBooks.length})',
                        isSelected: filter.status == AudiobookStatus.completed,
                        onSelected: () => filterNotifier.setStatus(AudiobookStatus.completed),
                        primary: primary,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Continue Listening Resume Banner
            if (resumeSuggestion != null && filter.query.isEmpty && filter.status == null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Builder(
                    builder: (context) {
                      final resumeTotalMs = resumeSuggestion.audiobook.totalDurationMs;
                      final resumeRatio = resumeTotalMs > 0
                          ? (resumeSuggestion.positionMs / resumeTotalMs).clamp(0.0, 1.0)
                          : 0.0;
                      final resumePercentage = (resumeRatio * 100).round();

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF271E38) : ClayColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ClayColors.softLilac.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: ClayColors.deepPurple.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            AudiobookCover(
                              coverPath: resumeSuggestion.audiobook.coverPath,
                              title: resumeSuggestion.audiobook.title,
                              author: resumeSuggestion.audiobook.author,
                              width: 64,
                              height: 64,
                              borderRadius: 12,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resumeSuggestion.audiobook.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : ClayColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    resumeSuggestion.audiobook.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white70 : ClayColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '$resumePercentage% completed',
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: ClayColors.primaryPurple,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ClayColors.primaryPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: Text(
                                'Resume',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () {
                                _openPlayer(context, resumeSuggestion.audiobook, autoPlay: true);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Storage Error State
            if (libState.errorMessage != null && libState.allBooks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storage_rounded,
                          size: 48,
                          color: Colors.redAccent,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Unable to load audiobook storage',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : ClayColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          libState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: ClayColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(audiobookLibraryProvider.notifier).refresh(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClayColors.primaryPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // Empty State
            else if (libState.allBooks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AudiobookEmptyState(
                  onImport: () => context.push('/audiobooks/import'),
                ),
              )
            // Default 3 Sections View (Current, Not Started, Completed)
            else if (isDefaultSectionView) ...[
              // Current Section
              SliverToBoxAdapter(
                child: AudiobookSection(
                  title: 'Current',
                  badgeColor: ClayColors.primaryPurple,
                  audiobooks: currentBooks,
                  localDb: localDb,
                  onBookTap: (book) => _openDetailsOrPlayer(context, book),
                  onBookPlay: (book) => _openPlayer(context, book, autoPlay: true),
                  onBookDelete: (book) => _confirmDelete(context, book),
                ),
              ),

              // Not Started Section
              SliverToBoxAdapter(
                child: AudiobookSection(
                  title: 'Not Started',
                  badgeColor: ClayColors.textMuted,
                  audiobooks: notStartedBooks,
                  localDb: localDb,
                  onBookTap: (book) => _openDetailsOrPlayer(context, book),
                  onBookPlay: (book) => _openPlayer(context, book, autoPlay: true),
                  onBookDelete: (book) => _confirmDelete(context, book),
                ),
              ),

              // Completed Section
              SliverToBoxAdapter(
                child: AudiobookSection(
                  title: 'Completed',
                  badgeColor: const Color(0xFF43A047),
                  audiobooks: completedBooks,
                  localDb: localDb,
                  onBookTap: (book) => _openDetailsOrPlayer(context, book),
                  onBookPlay: (book) => _openPlayer(context, book, autoPlay: true),
                  onBookDelete: (book) => _confirmDelete(context, book),
                ),
              ),
            ]
            // Filtered or Search View
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Found (${books.length})',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : ClayColors.textDark,
                        ),
                      ),
                      Row(
                        children: [
                          PopupMenuButton<String>(
                            initialValue: filter.sortBy,
                            tooltip: 'Sort by',
                            icon: Icon(Icons.sort_rounded, size: 20, color: primary),
                            onSelected: (val) => filterNotifier.setSortBy(val),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'recentlyAdded',
                                child: Text('Recently Added'),
                              ),
                              const PopupMenuItem(
                                value: 'title',
                                child: Text('Title (A-Z)'),
                              ),
                              const PopupMenuItem(
                                value: 'author',
                                child: Text('Author (A-Z)'),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              filter.gridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                              size: 20,
                              color: primary,
                            ),
                            tooltip: filter.gridView ? 'Switch to List' : 'Switch to Grid',
                            onPressed: () => filterNotifier.toggleGridView(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (books.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 56,
                            color: isDark ? Colors.white24 : ClayColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No matching audiobooks',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : ClayColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try a different title or author search.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: ClayColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (filter.gridView)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = books[index];
                        final prog = localDb.getProgress(book.id);
                        return AudiobookCard(
                          audiobook: book,
                          progress: prog,
                          width: double.infinity,
                          onTap: () => _openDetailsOrPlayer(context, book),
                          onPlay: () => _openPlayer(context, book, autoPlay: true),
                          onDelete: () => _confirmDelete(context, book),
                        );
                      },
                      childCount: books.length,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = books[index];
                        final prog = localDb.getProgress(book.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AudiobookListTile(
                            audiobook: book,
                            progress: prog,
                            onTap: () => _openDetailsOrPlayer(context, book),
                            onMoreOptions: () => _showBookOptions(context, book),
                          ),
                        );
                      },
                      childCount: books.length,
                    ),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color primary,
    required bool isDark,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: ClayColors.primaryPurple,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : ClayColors.textDark),
      ),
      backgroundColor: isDark ? const Color(0xFF271E38) : ClayColors.cardBg,
      side: BorderSide(
        color: isSelected
            ? ClayColors.primaryPurple
            : (isDark ? Colors.white12 : ClayColors.clayBorder),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (_) => onSelected(),
    );
  }

  void _openDetailsOrPlayer(BuildContext context, Audiobook book) {
    context.push('/audiobooks/${book.id}');
  }

  void _openPlayer(BuildContext context, Audiobook book, {bool autoPlay = false}) async {
    final playbackService = ref.read(audiobookPlaybackServiceProvider);
    await playbackService.loadAudiobook(book: book, autoPlay: autoPlay);
    if (context.mounted) {
      context.push('/audiobooks/${book.id}/player');
    }
  }

  void _confirmDelete(BuildContext context, Audiobook book) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: ClayColors.cardBg,
        title: Text(
          'Remove Audiobook?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ClayColors.textDark),
        ),
        content: Text(
          'Are you sure you want to remove this audiobook from your library?',
          style: GoogleFonts.inter(fontSize: 14, color: ClayColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(audiobookLibraryProvider.notifier).deleteAudiobook(book.id);
            },
            child: Text('Remove', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showBookOptions(BuildContext context, Audiobook book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF271E38) : ClayColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: ClayColors.primaryPurple),
                title: Text('View Details', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/audiobooks/${book.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded, color: ClayColors.primaryPurple),
                title: Text('Play Audiobook', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _openPlayer(context, book, autoPlay: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: Text('Remove from Library', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, book);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

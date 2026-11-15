import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/audiobook.dart';
import '../providers/audiobook_library_provider.dart';
import '../providers/audiobook_providers.dart';
import '../widgets/audiobook_cover.dart';
import '../widgets/audiobook_grid.dart';
import '../widgets/audiobook_list_tile.dart';
import '../../utils/audiobook_duration_utils.dart';

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
    final primary = isDark ? AppColors.gold : AppColors.brown;

    final filter = ref.watch(audiobookLibraryFilterProvider);
    final filterNotifier = ref.read(audiobookLibraryFilterProvider.notifier);
    final books = ref.watch(filteredAudiobooksProvider);
    final localDb = ref.watch(audiobookLocalDatasourceProvider);
    final resumeSuggestion = ref.watch(audiobookResumeSuggestionProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Audiobooks',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: isDark ? AppColors.ivory : AppColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded),
            tooltip: 'All Bookmarks',
            onPressed: () => context.push('/audiobooks/bookmarks'),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Listening History',
            onPressed: () => context.push('/audiobooks/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Audiobook Settings',
            onPressed: () => context.push('/audiobooks/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: isDark ? AppColors.espresso : AppColors.ivory,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Import'),
        onPressed: () => context.push('/audiobooks/import'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(audiobookLibraryProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // Search Bar & Import Action Row
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => filterNotifier.setQuery(val),
                        decoration: InputDecoration(
                          hintText: 'Search books and authors...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    filterNotifier.setQuery('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? AppColors.card : AppColors.parchment,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
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
                  child: Row(
                    children: [
                      _buildStatusFilterChip(
                        label: 'All',
                        isSelected: filter.status == null,
                        onSelected: () => filterNotifier.setStatus(null),
                        primary: primary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'Current',
                        isSelected: filter.status == AudiobookStatus.current,
                        onSelected: () => filterNotifier.setStatus(AudiobookStatus.current),
                        primary: primary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'Not started',
                        isSelected: filter.status == AudiobookStatus.notStarted,
                        onSelected: () => filterNotifier.setStatus(AudiobookStatus.notStarted),
                        primary: primary,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip(
                        label: 'Completed',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2C1810), AppColors.card]
                            : [AppColors.parchment, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        AudiobookCover(
                          coverPath: resumeSuggestion.audiobook.coverPath,
                          title: resumeSuggestion.audiobook.title,
                          author: resumeSuggestion.audiobook.author,
                          width: 56,
                          height: 56,
                          borderRadius: 8,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CONTINUE LISTENING',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: primary,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                resumeSuggestion.audiobook.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.ivory : AppColors.textDark,
                                ),
                              ),
                              Text(
                                resumeSuggestion.chapterTitle ??
                                    'Position: ${AudiobookDurationUtils.formatDuration(Duration(milliseconds: resumeSuggestion.positionMs))}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: isDark ? AppColors.espresso : AppColors.ivory,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          onPressed: () {
                            _openPlayer(context, resumeSuggestion.audiobook, autoPlay: true);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Controls Bar: View mode toggle & Sort by dropdown
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'All Audiobooks (${books.length})',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.ivory : AppColors.textDark,
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

            // Book List or Grid
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
                          Icons.headphones_rounded,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No audiobooks found',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.ivory : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Import audio files or folders to start listening.\nSupported formats: MP3, M4B, M4A, OGG, OPUS.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: isDark ? AppColors.espresso : AppColors.ivory,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Import Audiobook'),
                          onPressed: () => context.push('/audiobooks/import'),
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
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final book = books[index];
                      final prog = localDb.getProgress(book.id);
                      return AudiobookGridCard(
                        audiobook: book,
                        progress: prog,
                        onTap: () => _openDetailsOrPlayer(context, book),
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
      selectedColor: primary,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? (isDark ? AppColors.espresso : AppColors.ivory)
            : (isDark ? AppColors.ivory : AppColors.textDark),
      ),
      backgroundColor: isDark ? AppColors.card : AppColors.parchment,
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

  void _showBookOptions(BuildContext context, Audiobook book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.espresso : AppColors.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/audiobooks/${book.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('Play Audiobook'),
                onTap: () {
                  Navigator.pop(context);
                  _openPlayer(context, book, autoPlay: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Remove from Library', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(audiobookLibraryProvider.notifier).deleteAudiobook(book.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

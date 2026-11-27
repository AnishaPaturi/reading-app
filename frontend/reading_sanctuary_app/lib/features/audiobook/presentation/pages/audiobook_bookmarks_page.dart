import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/audiobook_providers.dart';
import '../../utils/audiobook_duration_utils.dart';

class AudiobookBookmarksPage extends ConsumerStatefulWidget {
  const AudiobookBookmarksPage({super.key});

  @override
  ConsumerState<AudiobookBookmarksPage> createState() => _AudiobookBookmarksPageState();
}

class _AudiobookBookmarksPageState extends ConsumerState<AudiobookBookmarksPage> {
  String _activeCategory = 'all'; // 'all', 'favorites', 'quote', 'note', 'revisit'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    final bookmarkService = ref.watch(audiobookBookmarkServiceProvider);
    final localDb = ref.watch(audiobookLocalDatasourceProvider);

    final allBookmarks = bookmarkService.getAllBookmarks(
      categoryFilter: (_activeCategory != 'all' && _activeCategory != 'favorites') ? _activeCategory : null,
      onlyFavorites: _activeCategory == 'favorites',
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Saved Bookmarks',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? AppColors.ivory : AppColors.textDark,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('all', 'All (${bookmarkService.getAllBookmarks().length})', primary, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('favorites', 'Favorites ★', primary, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('quote', 'Quotes', primary, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('note', 'Notes', primary, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('revisit', 'Revisit', primary, isDark),
              ],
            ),
          ),
          const Divider(),

          Expanded(
            child: allBookmarks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 54, color: Colors.grey.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No bookmarks saved yet',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.ivory : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap the bookmark icon while listening to save notable moments, quotes, or timestamps.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: allBookmarks.length,
                    itemBuilder: (context, index) {
                      final bm = allBookmarks[index];
                      final book = localDb.getAudiobook(bm.audiobookId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        color: isDark ? AppColors.card : AppColors.parchment,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: IconButton(
                            icon: Icon(
                              bm.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: bm.isFavorite ? AppColors.gold : Colors.grey,
                            ),
                            onPressed: () async {
                              await bookmarkService.toggleFavorite(bm.audiobookId, bm.id);
                              setState(() {});
                            },
                          ),
                          title: Text(
                            bm.title,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '${book?.title ?? "Audiobook"} · ${AudiobookDurationUtils.formatDuration(Duration(milliseconds: bm.positionMs))}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (bm.note != null && bm.note!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  bm.note!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: bm.category == 'quote' ? FontStyle.italic : FontStyle.normal,
                                    color: isDark ? AppColors.ivory.withValues(alpha: 0.8) : AppColors.textDark.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                            onPressed: () async {
                              await bookmarkService.deleteBookmark(bm.audiobookId, bm.id);
                              setState(() {});
                            },
                          ),
                          onTap: () async {
                            if (book != null) {
                              final playback = ref.read(audiobookPlaybackServiceProvider);
                              await playback.loadAudiobook(
                                book: book,
                                initialTrackIndex: bm.trackIndex,
                                initialPosition: Duration(milliseconds: bm.positionMs),
                                autoPlay: true,
                              );
                              if (context.mounted) {
                                context.push('/audiobooks/${book.id}/player');
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String cat, String label, Color primary, bool isDark) {
    final isSelected = _activeCategory == cat;
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
      onSelected: (_) => setState(() => _activeCategory = cat),
    );
  }
}

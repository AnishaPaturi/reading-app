import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/models/audiobook.dart';
import '../providers/audiobook_library_provider.dart';
import '../providers/audiobook_providers.dart';
import '../widgets/audiobook_cover.dart';
import '../../utils/audiobook_duration_utils.dart';

class AudiobookDetailsPage extends ConsumerStatefulWidget {
  final String audiobookId;

  const AudiobookDetailsPage({
    super.key,
    required this.audiobookId,
  });

  @override
  ConsumerState<AudiobookDetailsPage> createState() => _AudiobookDetailsPageState();
}

class _AudiobookDetailsPageState extends ConsumerState<AudiobookDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final localDb = ref.watch(audiobookLocalDatasourceProvider);
    final book = localDb.getAudiobook(widget.audiobookId);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    if (book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Audiobook not found')),
      );
    }

    final tracks = localDb.getTracksForBook(book.id);
    final progress = localDb.getProgress(book.id);
    final bookmarks = localDb.getBookmarks(book.id);

    final posMs = progress?.positionMs ?? 0;
    final totalMs = book.totalDurationMs;
    final ratio = totalMs > 0 ? (posMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.image_outlined),
            tooltip: 'Change Cover',
            onPressed: () => _showCoverOptions(context, book),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, book),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: AudiobookCover(
                coverPath: book.coverPath,
                title: book.title,
                author: book.author,
                width: 180,
                height: 180,
                borderRadius: 14,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              book.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.ivory : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              book.author,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
            if (book.narrator != null) ...[
              const SizedBox(height: 2),
              Text(
                'Narrated by ${book.narrator}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Progress Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.card : AppColors.parchment,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        book.status == AudiobookStatus.completed
                            ? 'Completed'
                            : (ratio > 0 ? '${(ratio * 100).toInt()}% completed' : 'Not started'),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${AudiobookDurationUtils.formatDuration(Duration(milliseconds: posMs))} / ${AudiobookDurationUtils.formatDuration(Duration(milliseconds: totalMs))}',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 5,
                      backgroundColor: isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Button: Play / Resume
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: isDark ? AppColors.espresso : AppColors.ivory,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 28),
                label: Text(
                  ratio > 0 && ratio < 1.0 ? 'Resume Playback' : 'Start Listening',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                onPressed: () async {
                  final playback = ref.read(audiobookPlaybackServiceProvider);
                  await playback.loadAudiobook(book: book, autoPlay: true);
                  if (context.mounted) {
                    context.push('/audiobooks/${book.id}/player');
                  }
                },
              ),
            ),

            const SizedBox(height: 26),

            // Track List
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tracks (${tracks.length})',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.ivory : AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tracks.length,
              itemBuilder: (context, index) {
                final t = tracks[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.withOpacity(0.15),
                    child: Text(
                      '${t.trackOrder}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  title: Text(
                    t.chapterTitle ?? t.fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Text(
                    AudiobookDurationUtils.formatDuration(Duration(milliseconds: t.durationMs)),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  onTap: () async {
                    final playback = ref.read(audiobookPlaybackServiceProvider);
                    await playback.loadAudiobook(
                      book: book,
                      initialTrackIndex: index,
                      autoPlay: true,
                    );
                    if (context.mounted) {
                      context.push('/audiobooks/${book.id}/player');
                    }
                  },
                );
              },
            ),

            if (bookmarks.isNotEmpty) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bookmarks (${bookmarks.length})',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.ivory : AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...bookmarks.map((b) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      b.isFavorite ? Icons.star_rounded : Icons.bookmark_rounded,
                      color: b.isFavorite ? AppColors.gold : primary,
                    ),
                    title: Text(b.title),
                    subtitle: Text(
                      '${b.category.toUpperCase()} · ${AudiobookDurationUtils.formatDuration(Duration(milliseconds: b.positionMs))}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    onTap: () async {
                      final playback = ref.read(audiobookPlaybackServiceProvider);
                      await playback.loadAudiobook(
                        book: book,
                        initialTrackIndex: b.trackIndex,
                        initialPosition: Duration(milliseconds: b.positionMs),
                        autoPlay: true,
                      );
                      if (context.mounted) {
                        context.push('/audiobooks/${book.id}/player');
                      }
                    },
                  )),
            ],

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _showCoverOptions(BuildContext context, Audiobook book) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.file_upload_outlined),
                title: const Text('Pick Image from Device'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(type: FileType.image);
                  if (result != null && result.files.single.path != null) {
                    final artworkService = ref.read(audiobookArtworkServiceProvider);
                    final savedPath = await artworkService.saveCustomArtwork(result.files.single.path!);
                    if (savedPath != null) {
                      final updated = book.copyWith(coverPath: savedPath);
                      await ref.read(audiobookLocalDatasourceProvider).updateAudiobook(updated);
                      setState(() {});
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.search_rounded),
                title: const Text('Search Online Covers (OpenLibrary)'),
                onTap: () {
                  Navigator.pop(context);
                  _searchOnlineCoverDialog(context, book);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _searchOnlineCoverDialog(BuildContext context, Audiobook book) async {
    final artworkService = ref.read(audiobookArtworkServiceProvider);
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: artworkService.searchOnlineCovers(title: book.title, author: book.author),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final results = snapshot.data!;
            if (results.isEmpty) {
              return AlertDialog(
                title: const Text('Online Covers'),
                content: const Text('No matching covers found for this book.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                ],
              );
            }

            return AlertDialog(
              title: const Text('Select a Cover'),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final item = results[index];
                    return InkWell(
                      onTap: () async {
                        final savedPath = await artworkService.downloadAndSaveCover(item.fullCoverUrl);
                        if (savedPath != null) {
                          final updated = book.copyWith(coverPath: savedPath);
                          await ref.read(audiobookLocalDatasourceProvider).updateAudiobook(updated);
                          if (mounted) setState(() {});
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(item.thumbnailUrl, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, Audiobook book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Audiobook'),
        content: Text('Are you sure you want to remove "${book.title}" from your library? Audio files on your device will remain intact.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(audiobookLibraryProvider.notifier).deleteAudiobook(book.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../core/sync/providers/sync_providers.dart';

class StorageManagementScreen extends ConsumerWidget {
  const StorageManagementScreen({super.key});

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(downloadManagerProvider);
    final downloads = manager.getAllDownloads();
    final totalBytes = manager.calculateTotalStorageBytes();
    final totalFormatted = _formatBytes(totalBytes);
    final dateFormatter = DateFormat.yMMMd();

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/settings'),
        ),
        title: Text(
          'Storage & Offline',
          style: GoogleFonts.inter(
            color: ClayColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              tooltip: 'Clear all downloads',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: Text('Clear All Downloads', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                    content: Text(
                      'Remove all downloaded books and audio files from this device? Your notes, bookmarks and cloud copies will remain safe.',
                      style: GoogleFonts.inter(color: ClayColors.textMuted),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Clear All', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await manager.clearAllDownloads();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cleared all downloaded files')),
                    );
                  }
                }
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Storage Card
                ClayCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7FE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFDDD2F5)),
                        ),
                        child: const Icon(Icons.sd_storage_rounded, color: ClayColors.deepPurple, size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              totalFormatted,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: ClayColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${downloads.length} offline book file(s) stored on device',
                              style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Downloaded Files (${downloads.length})',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: ClayColors.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (downloads.isEmpty)
                  ClayCard(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7FE),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFDDD2F5)),
                            ),
                            child: const Icon(Icons.cloud_download_rounded, color: ClayColors.deepPurple, size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No books downloaded for offline reading',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: ClayColors.textDark, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Open any book in your library and tap "Download for Offline" to read without internet.',
                            style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final task in downloads)
                    ClayCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7FE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDDD2F5)),
                          ),
                          child: Icon(
                            task.format.contains('MP3') || task.format.contains('M4B')
                                ? Icons.headphones_rounded
                                : Icons.menu_book_rounded,
                            color: ClayColors.deepPurple,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          task.bookTitle.isNotEmpty ? task.bookTitle : task.fileName,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ClayColors.textDark, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${task.format} · ${_formatBytes(task.totalBytes)}${task.downloadedAt != null ? ' · ${dateFormatter.format(task.downloadedAt!)}' : ''}',
                          style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          tooltip: 'Delete download',
                          onPressed: () async {
                            await manager.deleteDownload(task.fileId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Removed "${task.fileName}" from offline storage')),
                              );
                            }
                          },
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/sync/providers/sync_providers.dart';
import '../../../offline/domain/models/download_task.dart';

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
      appBar: AppBar(
        title: const Text('Storage & Offline'),
        actions: [
          if (downloads.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear all downloads',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear All Downloads'),
                    content: const Text(
                      'Remove all downloaded books and audio files from this device? Your notes, bookmarks and cloud copies will remain safe.',
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE05A7A)),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Clear All'),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Storage Card
                Card(
                  color: AppColors.card,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.walnut,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.sd_storage_outlined, color: AppColors.gold, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalFormatted,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${downloads.length} offline book file(s) stored on device',
                                style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Downloaded Files (${downloads.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (downloads.isEmpty)
                  Card(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.cloud_download_outlined, color: AppColors.textLightSecondary, size: 48),
                            SizedBox(height: 12),
                            Text(
                              'No books downloaded for offline reading',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Open any book in your library and tap "Download for Offline" to read without internet.',
                              style: TextStyle(color: AppColors.textLightSecondary, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  for (final task in downloads)
                    Card(
                      color: AppColors.card,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.walnut,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            task.format.contains('MP3') || task.format.contains('M4B')
                                ? Icons.headphones
                                : Icons.menu_book,
                            color: AppColors.gold,
                          ),
                        ),
                        title: Text(
                          task.bookTitle.isNotEmpty ? task.bookTitle : task.fileName,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textLight),
                        ),
                        subtitle: Text(
                          '${task.format} · ${_formatBytes(task.totalBytes)}${task.downloadedAt != null ? ' · ${dateFormatter.format(task.downloadedAt!)}' : ''}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textLightSecondary),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFE05A7A), size: 20),
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

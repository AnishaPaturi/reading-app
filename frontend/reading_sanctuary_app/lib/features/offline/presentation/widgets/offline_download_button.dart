import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../domain/models/download_task.dart';
import '../../../../core/sync/providers/sync_providers.dart';

class OfflineDownloadButton extends ConsumerWidget {
  final String bookId;
  final String fileId;
  final String bookTitle;
  final String fileName;
  final String format;

  const OfflineDownloadButton({
    super.key,
    required this.bookId,
    required this.fileId,
    required this.bookTitle,
    required this.fileName,
    required this.format,
  });

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(fileDownloadTaskProvider(fileId));
    final manager = ref.read(downloadManagerProvider);

    if (task == null || task.status == DownloadStatus.notDownloaded) {
      return OutlinedButton.icon(
        onPressed: () {
          manager.downloadBookFile(
            bookId: bookId,
            fileId: fileId,
            bookTitle: bookTitle,
            fileName: fileName,
            format: format,
          );
        },
        icon: const Icon(Icons.download_for_offline_outlined, size: 18),
        label: const Text('Download for Offline'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textLight,
          side: const BorderSide(color: AppColors.gold, width: 1),
        ),
      );
    }

    if (task.status == DownloadStatus.downloading) {
      final percent = (task.progress * 100).round();
      return OutlinedButton.icon(
        onPressed: null,
        icon: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            value: task.progress > 0 ? task.progress : null,
            strokeWidth: 2,
            color: AppColors.gold,
          ),
        ),
        label: Text('Downloading $percent%'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textLightSecondary,
          side: const BorderSide(color: AppColors.textLightSecondary, width: 1),
        ),
      );
    }

    if (task.status == DownloadStatus.downloaded) {
      final sizeStr = _formatBytes(task.totalBytes);
      return PopupMenuButton<String>(
        tooltip: 'Offline options',
        onSelected: (val) {
          if (val == 'delete') {
            manager.deleteDownload(fileId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Removed "$fileName" from offline downloads')),
            );
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem(
            value: 'info',
            enabled: false,
            child: Text('Downloaded: $sizeStr', style: const TextStyle(fontSize: 13)),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Color(0xFFE05A7A), size: 18),
                SizedBox(width: 8),
                Text('Delete Download', style: TextStyle(color: Color(0xFFE05A7A))),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF5CB89A).withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF5CB89A).withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.offline_pin, color: Color(0xFF5CB89A), size: 18),
              const SizedBox(width: 6),
              Text(
                'Offline Ready ($sizeStr)',
                style: const TextStyle(
                  color: Color(0xFF5CB89A),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: Color(0xFF5CB89A), size: 16),
            ],
          ),
        ),
      );
    }

    // Failed state
    return OutlinedButton.icon(
      onPressed: () {
        manager.downloadBookFile(
          bookId: bookId,
          fileId: fileId,
          bookTitle: bookTitle,
          fileName: fileName,
          format: format,
        );
      },
      icon: const Icon(Icons.refresh, color: Color(0xFFE05A7A), size: 18),
      label: const Text('Download Failed · Retry'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE05A7A),
        side: const BorderSide(color: Color(0xFFE05A7A), width: 1),
      ),
    );
  }
}

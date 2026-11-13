import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
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
        label: Text('Download for Offline', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: ClayColors.deepPurple,
          side: const BorderSide(color: Color(0xFFDDD2F5), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            color: ClayColors.deepPurple,
          ),
        ),
        label: Text('Downloading $percent%', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: ClayColors.textMuted,
          side: const BorderSide(color: Color(0xFFDDD2F5), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            child: Text('Downloaded: $sizeStr', style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textDark)),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline_rounded, color: ClayColors.coral, size: 18),
                const SizedBox(width: 8),
                Text('Delete Download', style: GoogleFonts.inter(color: ClayColors.coral, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F6F0),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ClayColors.mint.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.offline_pin_rounded, color: ClayColors.mint, size: 18),
              const SizedBox(width: 6),
              Text(
                'Offline Ready ($sizeStr)',
                style: GoogleFonts.inter(
                  color: ClayColors.mint,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, color: ClayColors.mint, size: 16),
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
      icon: const Icon(Icons.refresh_rounded, color: ClayColors.coral, size: 18),
      label: Text('Download Failed · Retry', style: GoogleFonts.inter(color: ClayColors.coral, fontWeight: FontWeight.w600, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: ClayColors.coral,
        side: const BorderSide(color: Color(0xFFFFDDD7), width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../models/batch_import_state.dart';

class BatchImportProgressPanel extends StatelessWidget {
  final BatchImportState importState;
  final VoidCallback onCancel;
  final VoidCallback onRetryFailed;
  final VoidCallback onDismiss;
  final VoidCallback onViewLibrary;

  const BatchImportProgressPanel({
    super.key,
    required this.importState,
    required this.onCancel,
    required this.onRetryFailed,
    required this.onDismiss,
    required this.onViewLibrary,
  });

  @override
  Widget build(BuildContext context) {
    final isImporting = importState.isImporting;
    final isCompleted = importState.status == BatchImportStatus.completed;
    final isCancelled = importState.status == BatchImportStatus.cancelled;
    final hasFailures = importState.hasFailures;

    return ClayCard(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isImporting
                        ? Icons.cloud_upload_rounded
                        : (hasFailures
                            ? Icons.warning_amber_rounded
                            : (isCancelled ? Icons.cancel_outlined : Icons.check_circle_rounded)),
                    color: isImporting
                        ? ClayColors.deepPurple
                        : (hasFailures
                            ? const Color(0xFFB03A2E)
                            : (isCancelled ? ClayColors.coral : const Color(0xFF1E8449))),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isImporting
                        ? 'Importing Books...'
                        : (hasFailures
                            ? 'Import Completed with Issues'
                            : (isCancelled ? 'Import Cancelled' : 'Import Complete!')),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: ClayColors.textDark,
                    ),
                  ),
                ],
              ),
              Text(
                '${importState.completedCount + importState.failedCount}/${importState.totalCount}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: importState.overallProgress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFEDE5F8),
              valueColor: AlwaysStoppedAnimation<Color>(
                hasFailures && !isImporting ? const Color(0xFFB03A2E) : ClayColors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Progress status text
          if (isImporting && importState.currentProcessingTitle != null)
            Text(
              'Processing: ${importState.currentProcessingTitle}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ClayColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          else if (isCompleted && !hasFailures)
            Text(
              'All ${importState.completedCount} selected books have been added to your library.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E8449), fontWeight: FontWeight.w600),
            )
          else if (hasFailures)
            Text(
              '${importState.completedCount} succeeded, ${importState.failedCount} failed or uncertain. Failed books can be retried safely.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB03A2E)),
            ),

          // Specific failure list if failures exist
          if (hasFailures && importState.failedItems.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEDEC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: importState.failedItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFB03A2E)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${item.book.file.name}: ${item.errorMessage ?? "Unknown error"}',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF78281F)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isImporting)
                OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.stop_circle_outlined, size: 16, color: ClayColors.coral),
                  label: Text(
                    'Cancel Import',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ClayColors.coral),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFFC3A6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else ...[
                if (hasFailures) ...[
                  ElevatedButton.icon(
                    onPressed: onRetryFailed,
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                    label: Text(
                      'Retry Failed (${importState.failedCount})',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClayColors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (importState.completedCount > 0) ...[
                  OutlinedButton.icon(
                    onPressed: onViewLibrary,
                    icon: const Icon(Icons.local_library_rounded, size: 16, color: ClayColors.deepPurple),
                    label: Text(
                      'View Library',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ClayColors.deepPurple),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDDD2F5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Done',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ClayColors.textMuted),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

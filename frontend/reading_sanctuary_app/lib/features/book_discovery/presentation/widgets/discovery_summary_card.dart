import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

/// Summary bar displaying counts across all discovery categories.
/// Provides clear distinction between importable and non-importable items.
class DiscoverySummaryCard extends StatelessWidget {
  final int totalCount;
  final int newCount;
  final int alreadyImportedCount;
  final int duplicateInScanCount;
  final int unverifiedCount;
  final int invalidOrErrorCount;
  final VoidCallback? onRetryVerification;

  const DiscoverySummaryCard({
    super.key,
    required this.totalCount,
    required this.newCount,
    required this.alreadyImportedCount,
    required this.duplicateInScanCount,
    required this.unverifiedCount,
    required this.invalidOrErrorCount,
    this.onRetryVerification,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: Colors.white,
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discovery Summary',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.textDark,
                ),
              ),
              Text(
                '$totalCount total discovered',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ClayColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricChip(
                label: 'Ready to Import',
                count: newCount,
                bgColor: const Color(0xFFE8F8F5),
                textColor: const Color(0xFF1E8449),
                icon: Icons.check_circle_rounded,
                isImportable: true,
              ),
              _buildMetricChip(
                label: 'In Library',
                count: alreadyImportedCount,
                bgColor: const Color(0xFFF4ECF7),
                textColor: const Color(0xFF6C3483),
                icon: Icons.library_books_rounded,
              ),
              _buildMetricChip(
                label: 'Duplicates',
                count: duplicateInScanCount,
                bgColor: const Color(0xFFFEF9E7),
                textColor: const Color(0xFFB7950B),
                icon: Icons.copy_rounded,
              ),
              if (unverifiedCount > 0)
                _buildMetricChip(
                  label: 'Unverified',
                  count: unverifiedCount,
                  bgColor: const Color(0xFFFDEDEC),
                  textColor: const Color(0xFFB03A2E),
                  icon: Icons.cloud_off_rounded,
                  trailingAction: onRetryVerification != null
                      ? InkWell(
                          onTap: onRetryVerification,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFFB03A2E)),
                                const SizedBox(width: 2),
                                Text(
                                  'Retry',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB03A2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
              if (invalidOrErrorCount > 0)
                _buildMetricChip(
                  label: 'Invalid / Errors',
                  count: invalidOrErrorCount,
                  bgColor: const Color(0xFFFADBD8),
                  textColor: const Color(0xFF78281F),
                  icon: Icons.error_outline_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required int count,
    required Color bgColor,
    required Color textColor,
    required IconData icon,
    bool isImportable = false,
    Widget? trailingAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isImportable ? textColor.withValues(alpha: 0.3) : Colors.transparent,
          width: isImportable ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          if (trailingAction != null) ...[
            const SizedBox(width: 6),
            trailingAction,
          ],
        ],
      ),
    );
  }
}

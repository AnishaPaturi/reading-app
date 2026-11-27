import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../models/classified_book.dart';
import '../../models/duplicate_status.dart';

class DiscoveredBookCard extends StatelessWidget {
  final ClassifiedBook book;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const DiscoveredBookCard({
    super.key,
    required this.book,
    required this.isSelected,
    this.onSelectChanged,
  });

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final isImportable = book.isImportable;
    final fileExt = book.file.extension.toUpperCase();
    final isAudio = book.file.isAudiobook;

    final (badgeBg, badgeText, badgeLabel, badgeIcon) = switch (book.classification) {
      DuplicateClassification.newBook => (
          const Color(0xFFE8F8F5),
          const Color(0xFF1E8449),
          'Ready to Import',
          Icons.check_circle_outline_rounded,
        ),
      DuplicateClassification.alreadyImported => (
          const Color(0xFFF4ECF7),
          const Color(0xFF6C3483),
          book.existingBookTitle != null
              ? 'Already in Library: "${book.existingBookTitle}"'
              : 'Already in Library',
          Icons.library_books_rounded,
        ),
      DuplicateClassification.duplicateInScan => (
          const Color(0xFFFEF9E7),
          const Color(0xFFB7950B),
          'Duplicate file in current scan',
          Icons.content_copy_rounded,
        ),
      DuplicateClassification.verificationFailed => (
          const Color(0xFFFDEDEC),
          const Color(0xFFB03A2E),
          'Verification failed • Cannot confirm novelty',
          Icons.cloud_off_rounded,
        ),
      DuplicateClassification.invalid => (
          const Color(0xFFFADBD8),
          const Color(0xFF78281F),
          book.errorMessage ?? 'Invalid format / corrupted',
          Icons.cancel_outlined,
        ),
      DuplicateClassification.error => (
          const Color(0xFFFADBD8),
          const Color(0xFF78281F),
          book.errorMessage ?? 'Read error',
          Icons.error_outline_rounded,
        ),
    };

    return Opacity(
      opacity: isImportable ? 1.0 : 0.78,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? ClayColors.deepPurple
                : (isImportable ? const Color(0xFFEADBFA) : const Color(0xFFEDE8F5)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ClayColors.deepPurple.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox column
              if (isImportable)
                Checkbox(
                  value: isSelected,
                  onChanged: onSelectChanged,
                  activeColor: ClayColors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                )
              else
                Tooltip(
                  message: 'This file cannot be imported ($badgeLabel)',
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.block_rounded,
                      size: 20,
                      color: ClayColors.textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                ),

              // Thumbnail Artwork / Format Block
              Container(
                width: 46,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isAudio
                        ? const [Color(0xFFFFC3A6), Color(0xFFFF926B)]
                        : const [Color(0xFFDDD2F5), Color(0xFFC7B2F0)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAudio ? Icons.headphones_rounded : Icons.menu_book_rounded,
                      color: isAudio ? const Color(0xFF8B3A1A) : ClayColors.deepPurple,
                      size: 20,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fileExt,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: isAudio ? const Color(0xFF8B3A1A) : ClayColors.deepPurple,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Title, path, format & status badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.file.name,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          _formatSize(book.file.sizeBytes),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: ClayColors.textMuted,
                          ),
                        ),
                        Text(' • ', style: GoogleFonts.inter(fontSize: 11.5, color: ClayColors.textMuted)),
                        Expanded(
                          child: Text(
                            book.file.pathOrUri,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ClayColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Classification badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 12, color: badgeText),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              badgeLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: badgeText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

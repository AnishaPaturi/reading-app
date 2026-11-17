import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../domain/annotation_type.dart';
import '../../domain/book_annotation.dart';
import 'highlight_color_picker.dart';

class AnnotationCard extends StatelessWidget {
  final BookAnnotation annotation;
  final VoidCallback onTapLocation;
  final VoidCallback? onEditNote;
  final ValueChanged<HighlightColorOption>? onChangeColor;
  final VoidCallback onDelete;

  const AnnotationCard({
    super.key,
    required this.annotation,
    required this.onTapLocation,
    this.onEditNote,
    this.onChangeColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isHighlight = annotation.type == AnnotationType.highlight;
    final isQuote = annotation.type == AnnotationType.quote;
    final color = annotation.displayColor;
    final hasPassage = annotation.selectedText != null && annotation.selectedText!.trim().isNotEmpty;
    final hasNote = annotation.noteText != null && annotation.noteText!.trim().isNotEmpty;

    return ClayCard(
      padding: const EdgeInsets.all(16),
      onTap: onTapLocation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              // Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isHighlight
                      ? color.withValues(alpha: 0.45)
                      : (isQuote ? const Color(0xFFEDE5F8) : const Color(0xFFECE5FA)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isHighlight
                        ? color
                        : (isQuote ? ClayColors.peachDark : ClayColors.primaryPurple),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHighlight
                          ? Icons.brush_rounded
                          : (isQuote ? Icons.format_quote_rounded : Icons.edit_note_rounded),
                      size: 13,
                      color: isHighlight
                          ? ClayColors.deepPurple
                          : (isQuote ? ClayColors.peachDark : ClayColors.primaryPurple),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHighlight
                          ? 'Highlight'
                          : (isQuote ? 'Quote' : 'Note'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isHighlight
                            ? ClayColors.deepPurple
                            : (isQuote ? ClayColors.peachDark : ClayColors.primaryPurple),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Page location
              if (annotation.pageNumber != null)
                Text(
                  'Page ${annotation.pageNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ClayColors.textMuted,
                  ),
                ),

              const Spacer(),

              // Popup menu: Edit, Change Color, Delete
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, size: 20, color: ClayColors.textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'edit' && onEditNote != null) {
                    onEditNote!();
                  } else if (val == 'color' && onChangeColor != null) {
                    _showColorChangeSheet(context);
                  } else if (val == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (ctx) => [
                  if (hasNote && onEditNote != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Note'),
                        ],
                      ),
                    ),
                  if (isHighlight && onChangeColor != null)
                    const PopupMenuItem(
                      value: 'color',
                      child: Row(
                        children: [
                          Icon(Icons.palette_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Change Color'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Passage Quote
          if (hasPassage) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isHighlight
                    ? color.withValues(alpha: 0.25)
                    : (isQuote ? const Color(0xFFFBF6EE) : const Color(0xFFFAF7FE)),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                    color: isHighlight
                        ? color
                        : (isQuote ? ClayColors.coral : ClayColors.primaryPurple),
                    width: 3.5,
                  ),
                ),
              ),
              child: Text(
                '“${annotation.selectedText!.trim()}”',
                maxLines: isQuote ? 8 : 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lora(
                  fontSize: isQuote ? 13.5 : 13,
                  fontStyle: FontStyle.italic,
                  color: ClayColors.textDark,
                ),
              ),
            ),
          ],

          // Note text if present
          if (hasNote) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.comment_rounded, size: 13, color: ClayColors.primaryPurple),
                      const SizedBox(width: 5),
                      Text(
                        'My Thoughts',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ClayColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    annotation.noteText!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.35,
                      color: ClayColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (annotation.isPendingSync)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 14, color: ClayColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      'Saved locally (pending sync)',
                      style: GoogleFonts.inter(fontSize: 10.5, color: ClayColors.textMuted),
                    ),
                  ],
                )
              else
                const SizedBox(),
              InkWell(
                onTap: onTapLocation,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        annotation.pageNumber != null ? 'Go to Page ${annotation.pageNumber}  →' : 'Go to Passage  →',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ClayColors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showColorChangeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Change Highlight Color',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: ClayColors.textDark),
              ),
              const SizedBox(height: 14),
              HighlightColorPicker(
                selectedHex: annotation.color,
                onColorSelected: (opt) {
                  Navigator.of(ctx).pop();
                  if (onChangeColor != null) {
                    onChangeColor!(opt);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

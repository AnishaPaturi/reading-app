import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import 'highlight_color_picker.dart';

enum AnnotationMenuAction {
  highlight,
  note,
  copy,
}

class AnnotationContextMenu extends StatelessWidget {
  final String selectedText;
  final int? pageNumber;
  final ValueChanged<HighlightColorOption> onHighlight;
  final VoidCallback onAddNote;
  final VoidCallback? onSaveQuote;
  final VoidCallback? onCopy;

  const AnnotationContextMenu({
    super.key,
    required this.selectedText,
    this.pageNumber,
    required this.onHighlight,
    required this.onAddNote,
    this.onSaveQuote,
    this.onCopy,
  });

  static Future<void> show(
    BuildContext context, {
    required String selectedText,
    int? pageNumber,
    required ValueChanged<HighlightColorOption> onHighlight,
    required VoidCallback onAddNote,
    VoidCallback? onSaveQuote,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => AnnotationContextMenu(
        selectedText: selectedText,
        pageNumber: pageNumber,
        onHighlight: (color) {
          Navigator.of(ctx).pop();
          onHighlight(color);
        },
        onAddNote: () {
          Navigator.of(ctx).pop();
          onAddNote();
        },
        onSaveQuote: onSaveQuote != null
            ? () {
                Navigator.of(ctx).pop();
                onSaveQuote();
              }
            : null,
        onCopy: () {
          Clipboard.setData(ClipboardData(text: selectedText));
          Navigator.of(ctx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passage copied to clipboard'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x332D234A),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle pill
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Selected passage preview
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7FA),
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                    left: BorderSide(color: ClayColors.coral, width: 3.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (pageNumber != null)
                      Text(
                        'PAGE $pageNumber',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: ClayColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '“${selectedText.trim()}”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: ClayColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Highlight palette row
              Text(
                'Highlight Color',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              HighlightColorPicker(
                onColorSelected: onHighlight,
              ),
              const SizedBox(height: 16),

              // Action buttons row: Quote, Note & Copy
              Row(
                children: [
                  if (onSaveQuote != null) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onSaveQuote,
                        icon: const Icon(Icons.format_quote_rounded, size: 18),
                        label: const Text('Quote'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ClayColors.deepPurple,
                          side: const BorderSide(color: Color(0xFFDDD2F5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onAddNote,
                      icon: const Icon(Icons.edit_note_rounded, size: 19),
                      label: const Text('Add Note'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ClayColors.deepPurple,
                        side: const BorderSide(color: Color(0xFFDDD2F5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onCopy,
                      icon: const Icon(Icons.content_copy_rounded, size: 17),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ClayColors.textDark,
                        side: const BorderSide(color: Color(0xFFDDD2F5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

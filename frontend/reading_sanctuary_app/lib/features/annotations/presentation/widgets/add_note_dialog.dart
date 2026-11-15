import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class AddNoteDialog extends StatefulWidget {
  final String? selectedText;
  final int? pageNumber;
  final String? initialNote;
  final bool isEditing;

  const AddNoteDialog({
    super.key,
    this.selectedText,
    this.pageNumber,
    this.initialNote,
    this.isEditing = false,
  });

  static Future<String?> show(
    BuildContext context, {
    String? selectedText,
    int? pageNumber,
    String? initialNote,
    bool isEditing = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AddNoteDialog(
        selectedText: selectedText,
        pageNumber: pageNumber,
        initialNote: initialNote,
        isEditing: isEditing,
      ),
    );
  }

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPassage = widget.selectedText != null && widget.selectedText!.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFECE5FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_note_rounded, color: ClayColors.deepPurple, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Edit Note' : 'Add Note',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: ClayColors.textDark,
                  ),
                ),
                if (widget.pageNumber != null)
                  Text(
                    'Page ${widget.pageNumber}',
                    style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPassage) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: ClayColors.coral, width: 3.5),
                  ),
                ),
                child: Text(
                  '“${widget.selectedText!.trim()}”',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.lora(
                    fontSize: 13.5,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF3B334B),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _controller,
              maxLines: 5,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14, color: ClayColors.textDark),
              decoration: InputDecoration(
                hintText: hasPassage
                    ? 'Write your thoughts about this passage...'
                    : 'Write a note for this page...',
                hintStyle: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13.5),
                filled: true,
                fillColor: const Color(0xFFFAF7FE),
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDDD2F5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFDDD2F5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: ClayColors.deepPurple, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: ClayColors.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isNotEmpty) {
              Navigator.of(context).pop(text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ClayColors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          child: Text(
            widget.isEditing ? 'Save Changes' : 'Save Note',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

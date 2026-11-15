import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../../utils/audiobook_duration_utils.dart';

class BookmarkDialog extends StatefulWidget {
  final Duration position;
  final String? chapterTitle;
  final void Function(String title, String? note, String category, bool isFavorite) onSave;

  const BookmarkDialog({
    super.key,
    required this.position,
    this.chapterTitle,
    required this.onSave,
  });

  @override
  State<BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<BookmarkDialog> {
  late final TextEditingController _titleController;
  final TextEditingController _noteController = TextEditingController();
  String _category = 'note'; // 'note', 'quote', 'revisit'
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final timeStr = AudiobookDurationUtils.formatDuration(widget.position);
    _titleController = TextEditingController(
      text: widget.chapterTitle != null
          ? '${widget.chapterTitle} ($timeStr)'
          : 'Bookmark at $timeStr',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.espresso : AppColors.ivory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Add Bookmark',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.ivory : AppColors.textDark,
            ),
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isFavorite ? AppColors.gold : Colors.grey,
            ),
            tooltip: 'Favorite',
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Position: ${AudiobookDurationUtils.formatDuration(widget.position)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: primary),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primary)),
              ),
              style: TextStyle(color: isDark ? AppColors.ivory : AppColors.textDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes or quote (optional)',
                labelStyle: TextStyle(color: primary),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primary)),
              ),
              style: TextStyle(color: isDark ? AppColors.ivory : AppColors.textDark),
            ),
            const SizedBox(height: 14),
            Text(
              'Category',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildCategoryChoice('note', 'Note', Icons.edit_note_rounded, primary),
                const SizedBox(width: 8),
                _buildCategoryChoice('quote', 'Quote', Icons.format_quote_rounded, primary),
                const SizedBox(width: 8),
                _buildCategoryChoice('revisit', 'Revisit', Icons.replay_rounded, primary),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: isDark ? AppColors.espresso : AppColors.ivory,
          ),
          onPressed: () {
            widget.onSave(
              _titleController.text.trim(),
              _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
              _category,
              _isFavorite,
            );
            Navigator.pop(context);
          },
          child: const Text('Save Bookmark'),
        ),
      ],
    );
  }

  Widget _buildCategoryChoice(String cat, String label, IconData icon, Color primary) {
    final selected = _category == cat;
    return ChoiceChip(
      avatar: Icon(icon, size: 16, color: selected ? Colors.white : primary),
      label: Text(label),
      selected: selected,
      selectedColor: primary,
      onSelected: (_) => setState(() => _category = cat),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class ReaderToolbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String format;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAnnotations;
  final VoidCallback? onSearch;
  final VoidCallback? onListenTts;

  const ReaderToolbar({
    super.key,
    required this.title,
    required this.format,
    required this.isBookmarked,
    required this.onBack,
    required this.onToggleBookmark,
    required this.onOpenSettings,
    required this.onOpenAnnotations,
    this.onSearch,
    this.onListenTts,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ClayColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.deepPurple),
        tooltip: 'Exit Reader',
        onPressed: onBack,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: ClayColors.textDark),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7FE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDD2F5)),
            ),
            child: Text(
              format.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: ClayColors.deepPurple,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (onListenTts != null)
          IconButton(
            icon: const Icon(Icons.record_voice_over_rounded, color: ClayColors.deepPurple),
            tooltip: 'Listen with Text-to-Speech',
            onPressed: onListenTts,
          ),
        IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: isBookmarked ? ClayColors.amber : ClayColors.deepPurple,
          ),
          tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
          onPressed: onToggleBookmark,
        ),
        if (onSearch != null)
          IconButton(
            icon: const Icon(Icons.search_rounded, color: ClayColors.deepPurple),
            tooltip: 'Search Document',
            onPressed: onSearch,
          ),
        IconButton(
          icon: const Icon(Icons.text_format_rounded, color: ClayColors.deepPurple),
          tooltip: 'Reader Preferences',
          onPressed: onOpenSettings,
        ),
        IconButton(
          icon: const Icon(Icons.notes_rounded, color: ClayColors.deepPurple),
          tooltip: 'Annotations & Notes',
          onPressed: onOpenAnnotations,
        ),
      ],
    );
  }
}

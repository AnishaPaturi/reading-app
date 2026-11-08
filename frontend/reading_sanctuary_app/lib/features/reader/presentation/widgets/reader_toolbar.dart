import 'package:flutter/material.dart';

class ReaderToolbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String format;
  final bool isBookmarked;
  final VoidCallback onBack;
  final VoidCallback onToggleBookmark;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenAnnotations;
  final VoidCallback? onSearch;

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
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              format.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: isBookmarked ? Colors.amber : null,
          ),
          tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
          onPressed: onToggleBookmark,
        ),
        if (onSearch != null)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Document',
            onPressed: onSearch,
          ),
        IconButton(
          icon: const Icon(Icons.text_format),
          tooltip: 'Reader Preferences',
          onPressed: onOpenSettings,
        ),
        IconButton(
          icon: const Icon(Icons.notes_outlined),
          tooltip: 'Annotations & Notes',
          onPressed: onOpenAnnotations,
        ),
      ],
    );
  }
}

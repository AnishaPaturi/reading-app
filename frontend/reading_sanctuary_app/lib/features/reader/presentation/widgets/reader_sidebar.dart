import 'package:flutter/material.dart';
import '../../data/models/reader_annotations.dart';

class ReaderSidebar extends StatelessWidget {
  final List<ReaderBookmark> bookmarks;
  final ValueChanged<ReaderBookmark> onSelectBookmark;
  final ValueChanged<ReaderBookmark> onDeleteBookmark;

  const ReaderSidebar({
    super.key,
    required this.bookmarks,
    required this.onSelectBookmark,
    required this.onDeleteBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.bookmarks_outlined),
                  const SizedBox(width: 8),
                  Text(
                    'Bookmarks (${bookmarks.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (bookmarks.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No bookmarks saved yet.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: bookmarks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final b = bookmarks[index];
                    return ListTile(
                      leading: const Icon(Icons.bookmark, color: Colors.amber),
                      title: Text(
                        b.label?.isNotEmpty == true
                            ? b.label!
                            : (b.pageNumber != null ? 'Page ${b.pageNumber}' : 'Bookmark ${index + 1}'),
                      ),
                      subtitle: b.note != null ? Text(b.note!) : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => onDeleteBookmark(b),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelectBookmark(b);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

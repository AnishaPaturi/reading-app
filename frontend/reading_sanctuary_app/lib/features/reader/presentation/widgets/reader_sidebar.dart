import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
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
      backgroundColor: ClayColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.bookmarks_rounded, color: ClayColors.deepPurple, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Bookmarks (${bookmarks.length})',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: ClayColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFDDD2F5), height: 1),
            if (bookmarks.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No bookmarks saved yet.',
                    style: GoogleFonts.inter(
                      color: ClayColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: bookmarks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final b = bookmarks[index];
                    return Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFDDD2F5)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.bookmark_rounded, color: ClayColors.amber),
                        title: Text(
                          b.label?.isNotEmpty == true
                              ? b.label!
                              : (b.pageNumber != null ? 'Page ${b.pageNumber}' : 'Bookmark ${index + 1}'),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: ClayColors.textDark,
                          ),
                        ),
                        subtitle: b.note != null
                            ? Text(
                                b.note!,
                                style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
                              )
                            : null,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: ClayColors.coral),
                          onPressed: () => onDeleteBookmark(b),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelectBookmark(b);
                        },
                      ),
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

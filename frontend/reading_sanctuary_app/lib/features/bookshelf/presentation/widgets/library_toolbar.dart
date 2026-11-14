import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class LibraryToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onCreateShelfTap;
  final VoidCallback? onManageTap;
  final VoidCallback? onAddBookTap;
  final String title;
  final String subtitle;

  const LibraryToolbar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCreateShelfTap,
    this.onManageTap,
    this.onAddBookTap,
    this.title = 'Your Bookshelves',
    this.subtitle = 'Curated corners for your collection',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: ClayColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Manage button (if provided)
            if (onManageTap != null) ...[
              OutlinedButton.icon(
                onPressed: onManageTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClayColors.primaryPurple,
                  side: const BorderSide(color: ClayColors.softLilac, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: Text(
                  'Manage',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            if (onAddBookTap != null) ...[
              ElevatedButton.icon(
                onPressed: onAddBookTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClayColors.deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: ClayColors.softLilac, width: 1),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Add Book',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            ElevatedButton.icon(
              onPressed: onCreateShelfTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayColors.primaryPurple,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: ClayColors.softLilac, width: 1),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'New Shelf',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Bar
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClayColors.clayBorder),
            boxShadow: [
              BoxShadow(
                color: ClayColors.deepPurple.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: GoogleFonts.inter(fontSize: 13.5, color: ClayColors.textDark),
            decoration: InputDecoration(
              hintText: 'Search shelves or titles...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: ClayColors.primaryPurple, size: 20),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: ClayColors.textMuted),
                      onPressed: onClearSearch,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}

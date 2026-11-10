import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/bookshelf_theme.dart';

class BookshelfHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onFilterTap;
  final VoidCallback? onMenuTap;
  final bool showMenuButton;
  final bool hasActiveFilters;

  const BookshelfHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterTap,
    this.onMenuTap,
    this.showMenuButton = false,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showMenuButton) ...[
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: BookshelfTheme.searchPill,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: BookshelfTheme.purpleAccent, size: 22),
              onPressed: onMenuTap,
              tooltip: 'Menu',
            ),
          ),
        ],

        // Search Pill
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: BookshelfTheme.searchPill,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF332050),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search books...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: BookshelfTheme.searchHint,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Clear or Search Icon
                if (searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: onClearSearch,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close_rounded,
                        color: BookshelfTheme.purpleAccent,
                        size: 18,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.search_rounded,
                    color: BookshelfTheme.purpleAccent,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Filter / Tune button
        GestureDetector(
          onTap: onFilterTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BookshelfTheme.filterButtonBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.tune_rounded,
                  color: BookshelfTheme.purpleAccent,
                  size: 22,
                ),
                if (hasActiveFilters)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF6A184),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

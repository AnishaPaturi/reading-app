import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/models/book.dart';
import '../theme/bookshelf_theme.dart';

class LibraryFilterSheet extends StatelessWidget {
  final Set<ReadingStatus> selectedStatuses;
  final ValueChanged<Set<ReadingStatus>> onStatusChanged;
  final bool isBookshelfView;
  final ValueChanged<bool> onViewModeChanged;
  final VoidCallback onAddBook;
  final VoidCallback onClearAll;

  const LibraryFilterSheet({
    super.key,
    required this.selectedStatuses,
    required this.onStatusChanged,
    required this.isBookshelfView,
    required this.onViewModeChanged,
    required this.onAddBook,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F3FD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: BookshelfTheme.searchHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Library',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF332050),
                ),
              ),
              if (selectedStatuses.isNotEmpty)
                TextButton(
                  onPressed: onClearAll,
                  child: Text(
                    'Clear filters',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BookshelfTheme.purpleAccent,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // View Mode Selector (Bookshelf 3D vs Cover Grid)
          Text(
            'View Mode',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BookshelfTheme.searchHint,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ViewModeButton(
                  icon: Icons.view_week_rounded,
                  label: '3D Bookshelf',
                  isSelected: isBookshelfView,
                  onTap: () => onViewModeChanged(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ViewModeButton(
                  icon: Icons.grid_view_rounded,
                  label: 'Cover Grid',
                  isSelected: !isBookshelfView,
                  onTap: () => onViewModeChanged(false),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Reading Status Filter
          Text(
            'Reading Status',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BookshelfTheme.searchHint,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // All Chip
              _FilterChip(
                label: 'All Books',
                isSelected: selectedStatuses.isEmpty,
                onTap: () => onStatusChanged({}),
              ),
              for (final status in ReadingStatus.values)
                _FilterChip(
                  label: status.label,
                  isSelected: selectedStatuses.contains(status),
                  onTap: () {
                    final next = Set<ReadingStatus>.from(selectedStatuses);
                    if (next.contains(status)) {
                      next.remove(status);
                    } else {
                      next.add(status);
                    }
                    onStatusChanged(next);
                  },
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Add New Book Action
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                onAddBook();
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Add New Book',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: BookshelfTheme.purpleAccent,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? BookshelfTheme.purpleAccent : BookshelfTheme.searchPill,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: BookshelfTheme.purpleAccent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF5A447F),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF5A447F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B45B3) : BookshelfTheme.searchPill,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF6B45B3).withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4C366B),
          ),
        ),
      ),
    );
  }
}

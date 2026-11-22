import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class ReaderSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onNextMatch;
  final VoidCallback onPrevMatch;
  final VoidCallback onClose;
  final int currentMatchIndex;
  final int totalMatches;
  final bool isSearching;

  const ReaderSearchBar({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.onNextMatch,
    required this.onPrevMatch,
    required this.onClose,
    required this.currentMatchIndex,
    required this.totalMatches,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    String counterText = '';
    if (isSearching) {
      counterText = 'Searching...';
    } else if (controller.text.trim().isNotEmpty) {
      if (totalMatches > 0) {
        counterText = '${currentMatchIndex + 1} of $totalMatches';
      } else {
        counterText = 'No matches';
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFDDD2F5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: ClayColors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14, color: ClayColors.textDark),
              decoration: const InputDecoration(
                hintText: 'Search in book...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: onQueryChanged,
            ),
          ),
          if (counterText.isNotEmpty) ...[
            Text(
              counterText,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: totalMatches > 0 ? ClayColors.deepPurple : ClayColors.coral,
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 22, color: ClayColors.deepPurple),
            tooltip: 'Previous match',
            visualDensity: VisualDensity.compact,
            onPressed: totalMatches > 0 ? onPrevMatch : null,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: ClayColors.deepPurple),
            tooltip: 'Next match',
            visualDensity: VisualDensity.compact,
            onPressed: totalMatches > 0 ? onNextMatch : null,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: ClayColors.textMuted),
            tooltip: 'Close search',
            visualDensity: VisualDensity.compact,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

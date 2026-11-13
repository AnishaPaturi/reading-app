import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class EmptyLibraryState extends StatelessWidget {
  final VoidCallback onCreateTap;
  final bool isSearch;

  const EmptyLibraryState({
    super.key,
    required this.onCreateTap,
    this.isSearch = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClayColors.clayBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ClayColors.deepPurple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClayColors.lightLilac.withValues(alpha: 0.4),
              border: Border.all(color: ClayColors.softLilac, width: 1.5),
            ),
            child: const Icon(
              Icons.shelves,
              color: ClayColors.primaryPurple,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No Matching Shelves' : 'Your Book Sanctuary Awaits',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: ClayColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearch
                ? 'Try a different keyword or create a new shelf.'
                : 'Create personalized shelves like "Dark Romance", "My TBR", or "Five-Star Reads" to arrange your collection.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: ClayColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreateTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.primaryPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ClayColors.softLilac, width: 1),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'Create a Bookshelf',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

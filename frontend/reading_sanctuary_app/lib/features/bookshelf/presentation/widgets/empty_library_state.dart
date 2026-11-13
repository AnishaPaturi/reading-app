import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEADBCE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              color: const Color(0xFF2C221E).withValues(alpha: 0.06),
              border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(
              Icons.shelves,
              color: Color(0xFF8C7CD6),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No Matching Shelves' : 'Your Book Sanctuary Awaits',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D234A),
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
              color: const Color(0xFF7A6E82),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCreateTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C221E),
              foregroundColor: const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
              ),
              elevation: 2,
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'Create a Bookshelf',
              style: GoogleFonts.cinzel(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

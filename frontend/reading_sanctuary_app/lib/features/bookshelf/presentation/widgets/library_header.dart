import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class LibraryHeader extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final bool showMenuButton;

  const LibraryHeader({
    super.key,
    this.onMenuTap,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showMenuButton) ...[
            InkWell(
              onTap: onMenuTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2D6C8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.menu_rounded, color: Color(0xFF2D234A), size: 22),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'YOUR PERSONAL READING SANCTUARY',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cinzel(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8C7CD6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFD4AF37)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'My Library',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: const Color(0xFF2D234A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your reading collection, arranged your way.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: ClayColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

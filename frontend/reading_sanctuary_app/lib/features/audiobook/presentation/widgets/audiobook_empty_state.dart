import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class AudiobookEmptyState extends StatelessWidget {
  final VoidCallback? onImport;

  const AudiobookEmptyState({super.key, this.onImport});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ClayColors.softLilac.withValues(alpha: 0.35),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ClayColors.clayBorder,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ClayColors.deepPurple.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.headphones_rounded,
                size: 48,
                color: ClayColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your audiobook sanctuary is waiting.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ClayColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "You haven't added any audiobooks yet.\nImport your first audiobook and start listening.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: ClayColors.textMuted,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
                shadowColor: ClayColors.deepPurple.withValues(alpha: 0.35),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Import Audiobook',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onPressed: onImport ?? () => context.push('/audiobooks/import'),
            ),
          ],
        ),
      ),
    );
  }
}

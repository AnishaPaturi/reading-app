import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/bookshelf_themes.dart';

class BookshelfThemePicker extends StatelessWidget {
  final String selectedThemeId;
  final ValueChanged<BookshelfThemeOption> onThemeSelected;

  const BookshelfThemePicker({
    super.key,
    required this.selectedThemeId,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shelf Aesthetic Theme',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D234A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the colors, mood, and material of this shelf',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7A6E82)),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: BookshelfThemes.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final theme = BookshelfThemes.all[index];
              final isSelected = theme.id == selectedThemeId;

              return InkWell(
                onTap: () => onThemeSelected(theme),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 135,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? theme.accentColor : Colors.white.withValues(alpha: 0.15),
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: theme.accentColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      else
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.accentColor,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.accentColor,
                              ),
                              child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            theme.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.textColor,
                            ),
                          ),
                          Text(
                            theme.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              color: theme.textColor.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

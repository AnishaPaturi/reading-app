import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../utils/bookshelf_layouts.dart';

class BookshelfLayoutSelector extends StatelessWidget {
  final BookshelfLayoutStyle selectedLayout;
  final ValueChanged<BookshelfLayoutStyle> onLayoutChanged;
  final BookshelfBackgroundStyle selectedBackground;
  final ValueChanged<BookshelfBackgroundStyle> onBackgroundChanged;

  const BookshelfLayoutSelector({
    super.key,
    required this.selectedLayout,
    required this.onLayoutChanged,
    required this.selectedBackground,
    required this.onBackgroundChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Display Layout',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ClayColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How books are arranged on this shelf',
          style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
        ),
        const SizedBox(height: 10),

        Row(
          children: BookshelfLayoutStyle.values.map((layout) {
            final isSelected = layout == selectedLayout;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onLayoutChanged(layout),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? ClayColors.primaryPurple : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? ClayColors.softLilac : ClayColors.clayBorder,
                        width: isSelected ? 1.8 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: ClayColors.primaryPurple.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          layout.icon,
                          size: 20,
                          color: isSelected ? Colors.white : ClayColors.textMuted,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          layout.label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : ClayColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        Text(
          'Shelf Background Style',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ClayColors.textDark,
          ),
        ),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BookshelfBackgroundStyle.values.map((bg) {
            final isSelected = bg == selectedBackground;
            return ChoiceChip(
              avatar: Icon(
                bg.icon,
                size: 16,
                color: isSelected ? Colors.white : ClayColors.textMuted,
              ),
              label: Text(
                bg.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : ClayColors.textDark,
                ),
              ),
              selected: isSelected,
              selectedColor: ClayColors.primaryPurple,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? ClayColors.softLilac : ClayColors.clayBorder,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              onSelected: (_) => onBackgroundChanged(bg),
            );
          }).toList(),
        ),
      ],
    );
  }
}

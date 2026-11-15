import 'package:flutter/material.dart';

class HighlightColorOption {
  final String name;
  final String hex;
  final Color color;

  const HighlightColorOption({
    required this.name,
    required this.hex,
    required this.color,
  });
}

class HighlightColors {
  static const List<HighlightColorOption> options = [
    HighlightColorOption(name: 'Warm Yellow', hex: '#F5E7A8', color: Color(0xFFF5E7A8)),
    HighlightColorOption(name: 'Dusty Rose', hex: '#FAD4D8', color: Color(0xFFFAD4D8)),
    HighlightColorOption(name: 'Soft Lavender', hex: '#E6DEF8', color: Color(0xFFE6DEF8)),
    HighlightColorOption(name: 'Sage Green', hex: '#D2E8D4', color: Color(0xFFD2E8D4)),
    HighlightColorOption(name: 'Muted Blue', hex: '#C8E2F8', color: Color(0xFFC8E2F8)),
  ];

  static HighlightColorOption get defaultColor => options[0];
}

class HighlightColorPicker extends StatelessWidget {
  final String? selectedHex;
  final ValueChanged<HighlightColorOption> onColorSelected;

  const HighlightColorPicker({
    super.key,
    this.selectedHex,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: HighlightColors.options.map((opt) {
        final isSelected = selectedHex?.toUpperCase() == opt.hex.toUpperCase();
        return GestureDetector(
          onTap: () => onColorSelected(opt),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: opt.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF2D234A) : Colors.black12,
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: opt.color.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Color(0xFF2D234A))
                : null,
          ),
        );
      }).toList(),
    );
  }
}

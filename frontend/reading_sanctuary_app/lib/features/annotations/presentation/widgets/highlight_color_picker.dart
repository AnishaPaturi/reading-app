import 'package:flutter/material.dart';
import '../../../../core/widgets/clay_components.dart';

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

enum HighlightStyle {
  solid,
  underline,
  wavy;

  String get label {
    switch (this) {
      case HighlightStyle.solid:
        return 'Solid';
      case HighlightStyle.underline:
        return 'Underline';
      case HighlightStyle.wavy:
        return 'Wavy';
    }
  }

  IconData get icon {
    switch (this) {
      case HighlightStyle.solid:
        return Icons.format_color_fill_rounded;
      case HighlightStyle.underline:
        return Icons.format_underlined_rounded;
      case HighlightStyle.wavy:
        return Icons.gesture_rounded;
    }
  }
}

class HighlightColors {
  static const List<HighlightColorOption> options = [
    HighlightColorOption(name: 'Lavender', hex: '#EDE5F8', color: Color(0xFFEDE5F8)),
    HighlightColorOption(name: 'Lilac', hex: '#C7B2F0', color: Color(0xFFC7B2F0)),
    HighlightColorOption(name: 'Rose', hex: '#FAD4D8', color: Color(0xFFFAD4D8)),
    HighlightColorOption(name: 'Butter', hex: '#FDF0AA', color: Color(0xFFFDF0AA)),
    HighlightColorOption(name: 'Mint', hex: '#A4DFD0', color: Color(0xFFA4DFD0)),
    HighlightColorOption(name: 'Sky', hex: '#B4D8F8', color: Color(0xFFB4D8F8)),
  ];

  static HighlightColorOption get defaultColor => options[0];

  /// Helper to find matching option or fallback to default
  static HighlightColorOption fromHex(String? hex) {
    if (hex == null) return defaultColor;
    return options.firstWhere(
      (opt) => opt.hex.toUpperCase() == hex.toUpperCase(),
      orElse: () => defaultColor,
    );
  }
}

class HighlightColorPicker extends StatelessWidget {
  final String? selectedHex;
  final HighlightStyle selectedStyle;
  final bool showStyles;
  final ValueChanged<HighlightColorOption> onColorSelected;
  final ValueChanged<HighlightStyle>? onStyleSelected;

  const HighlightColorPicker({
    super.key,
    this.selectedHex,
    this.selectedStyle = HighlightStyle.solid,
    this.showStyles = false,
    required this.onColorSelected,
    this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Color row
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: HighlightColors.options.map((opt) {
            final isSelected = selectedHex != null &&
                selectedHex!.toUpperCase() == opt.hex.toUpperCase();

            return Tooltip(
              message: opt.name,
              child: GestureDetector(
                onTap: () => onColorSelected(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: opt.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? ClayColors.deepPurple : const Color(0xFFDDD2F5),
                      width: isSelected ? 2.5 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: opt.color.withValues(alpha: 0.6),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 3),
                      ),
                      if (isSelected)
                        BoxShadow(
                          color: ClayColors.deepPurple.withValues(alpha: 0.25),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: Center(
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: ClayColors.deepPurple,
                          )
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Style selector
        if (showStyles) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE5F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: HighlightStyle.values.map((style) {
                final isSelected = selectedStyle == style;
                return GestureDetector(
                  onTap: () => onStyleSelected?.call(style),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x1A382761),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style.icon,
                          size: 15,
                          color: isSelected ? ClayColors.deepPurple : ClayColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          style.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? ClayColors.deepPurple : ClayColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

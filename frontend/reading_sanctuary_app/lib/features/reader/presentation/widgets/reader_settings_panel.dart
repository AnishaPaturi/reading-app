import 'package:flutter/material.dart';
import '../../data/models/reader_settings.dart';

class ReaderSettingsPanel extends StatelessWidget {
  final ReaderSettings settings;
  final ValueChanged<ReaderThemeMode> onThemeChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineSpacingChanged;
  final ValueChanged<ReaderMargin> onMarginChanged;
  final ValueChanged<Axis> onPageLayoutChanged;

  const ReaderSettingsPanel({
    super.key,
    required this.settings,
    required this.onThemeChanged,
    required this.onFontSizeChanged,
    required this.onLineSpacingChanged,
    required this.onMarginChanged,
    required this.onPageLayoutChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading Preferences',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Theme Selector
            Text('Theme', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildThemeButton('Light', ReaderThemeMode.light, const Color(0xFFFAFAFA), Colors.black),
                const SizedBox(width: 12),
                _buildThemeButton('Sepia', ReaderThemeMode.sepia, const Color(0xFFFBF0D9), const Color(0xFF5F4B32)),
                const SizedBox(width: 12),
                _buildThemeButton('Dark', ReaderThemeMode.dark, const Color(0xFF1E1E1E), Colors.white),
              ],
            ),
            const SizedBox(height: 20),

            // Font Size
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Font Size', style: Theme.of(context).textTheme.labelLarge),
                Text('${settings.fontSize.round()} pt'),
              ],
            ),
            Slider(
              value: settings.fontSize,
              min: 12,
              max: 32,
              divisions: 20,
              onChanged: onFontSizeChanged,
            ),
            const SizedBox(height: 12),

            // Line Spacing
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Line Spacing', style: Theme.of(context).textTheme.labelLarge),
                Text(settings.lineSpacing.toStringAsFixed(1)),
              ],
            ),
            Slider(
              value: settings.lineSpacing,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              onChanged: onLineSpacingChanged,
            ),
            const SizedBox(height: 12),

            // Margins
            Text('Margins', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ReaderMargin>(
              segments: const [
                ButtonSegment(value: ReaderMargin.narrow, label: Text('Narrow')),
                ButtonSegment(value: ReaderMargin.medium, label: Text('Medium')),
                ButtonSegment(value: ReaderMargin.wide, label: Text('Wide')),
              ],
              selected: {settings.margin},
              onSelectionChanged: (set) => onMarginChanged(set.first),
            ),
            const SizedBox(height: 12),

            // Page Layout
            Text('Scroll Direction', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<Axis>(
              segments: const [
                ButtonSegment(value: Axis.vertical, label: Text('Vertical')),
                ButtonSegment(value: Axis.horizontal, label: Text('Horizontal')),
              ],
              selected: {settings.pageLayout},
              onSelectionChanged: (set) => onPageLayoutChanged(set.first),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton(String label, ReaderThemeMode mode, Color bg, Color fg) {
    final isSelected = settings.themeMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => onThemeChanged(mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.3),
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

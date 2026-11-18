import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../providers/book_size_provider.dart';

class BookSizeSlider extends ConsumerWidget {
  const BookSizeSlider({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sizeState = ref.watch(bookSizeProvider);
    final notifier = ref.read(bookSizeProvider.notifier);

    if (!sizeState.isResizeModeActive) {
      return const SizedBox.shrink();
    }

    final selectedId = sizeState.selectedBookId;
    final double curFactor = selectedId != null ? sizeState.factorFor(selectedId) : 1.0;
    final String curPreset = selectedId != null ? sizeState.presetFor(selectedId) : 'M';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3ECFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClayColors.deepPurple.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: ClayColors.deepPurple.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.photo_size_select_small_rounded, color: ClayColors.deepPurple, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    selectedId != null ? 'Adjusting Selected Book' : 'Tap any book on the shelf to resize',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.textDark,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: notifier.autoResetAll,
                    child: Text(
                      'Reset All',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: ClayColors.coral),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    onPressed: notifier.done,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ClayColors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    ),
                    child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 12.5)),
                  ),
                ],
              ),
            ],
          ),

          if (selectedId != null) ...[
            const SizedBox(height: 12),
            // Height Slider & S/M/L Presets
            Row(
              children: [
                Text(
                  'Height',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ClayColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: ClayColors.deepPurple,
                      inactiveTrackColor: const Color(0xFFDDD2F5),
                      thumbColor: ClayColors.deepPurple,
                      trackHeight: 5,
                    ),
                    child: Slider(
                      value: curFactor,
                      min: 0.7,
                      max: 1.4,
                      divisions: 14,
                      label: '${(curFactor * 100).round()}%',
                      onChanged: (val) => notifier.setHeightFactor(selectedId, val),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(curFactor * 100).round()}%',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ClayColors.textDark),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // S / M / L Presets & Auto Reset for Book
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Presets: ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ClayColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    for (final preset in ['S', 'M', 'L'])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(preset),
                          selected: curPreset == preset,
                          onSelected: (_) => notifier.setPreset(selectedId, preset),
                          selectedColor: ClayColors.deepPurple,
                          labelStyle: TextStyle(
                            color: curPreset == preset ? Colors.white : ClayColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: notifier.autoResetSelected,
                  icon: const Icon(Icons.refresh_rounded, size: 14, color: ClayColors.deepPurple),
                  label: const Text('Reset', style: TextStyle(color: ClayColors.deepPurple, fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFC7B8E8)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

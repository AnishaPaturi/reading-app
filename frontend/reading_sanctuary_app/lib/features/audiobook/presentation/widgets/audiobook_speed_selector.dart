import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../data/models/audio_settings.dart';

class AudiobookSpeedSelector extends StatelessWidget {
  final double currentSpeed;
  final ValueChanged<double> onSpeedSelected;

  const AudiobookSpeedSelector({
    super.key,
    required this.currentSpeed,
    required this.onSpeedSelected,
  });

  static void show(
    BuildContext context, {
    required double currentSpeed,
    required ValueChanged<double> onSpeedSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: AudiobookSpeedSelector(
          currentSpeed: currentSpeed,
          onSpeedSelected: onSpeedSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                'Playback Speed',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                ),
              ),
            ),
            const Divider(color: Color(0xFFEDE5F8), height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: AudioSettings.availableSpeeds.length,
                itemBuilder: (context, index) {
                  final speed = AudioSettings.availableSpeeds[index];
                  final isSelected = (speed - currentSpeed).abs() < 0.01;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Material(
                      color: isSelected ? const Color(0xFFFAF7FE) : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isSelected ? const BorderSide(color: Color(0xFFDDD2F5)) : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected ? ClayColors.deepPurple : ClayColors.textMuted.withValues(alpha: 0.5),
                        ),
                        title: Text(
                          '${speed}x',
                          style: GoogleFonts.inter(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? ClayColors.deepPurple : ClayColors.textDark,
                            fontSize: 14.5,
                          ),
                        ),
                        trailing: speed == 1.0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F6F0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Normal',
                                  style: GoogleFonts.inter(
                                    color: ClayColors.mint,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () {
                          onSpeedSelected(speed);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import 'tts_voice_selector.dart';

class TtsSettingsPanel extends StatelessWidget {
  final double speechRate;
  final double pitch;
  final Map<String, String>? selectedVoice;
  final List<Map<String, String>> availableVoices;
  final ValueChanged<double> onSpeechRateChanged;
  final ValueChanged<double> onPitchChanged;
  final ValueChanged<Map<String, String>> onVoiceChanged;

  const TtsSettingsPanel({
    super.key,
    required this.speechRate,
    required this.pitch,
    required this.selectedVoice,
    required this.availableVoices,
    required this.onSpeechRateChanged,
    required this.onPitchChanged,
    required this.onVoiceChanged,
  });

  static void show(
    BuildContext context, {
    required double speechRate,
    required double pitch,
    required Map<String, String>? selectedVoice,
    required List<Map<String, String>> availableVoices,
    required ValueChanged<double> onSpeechRateChanged,
    required ValueChanged<double> onPitchChanged,
    required ValueChanged<Map<String, String>> onVoiceChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: TtsSettingsPanel(
          speechRate: speechRate,
          pitch: pitch,
          selectedVoice: selectedVoice,
          availableVoices: availableVoices,
          onSpeechRateChanged: onSpeechRateChanged,
          onPitchChanged: onPitchChanged,
          onVoiceChanged: onVoiceChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Text-to-Speech Settings',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ClayColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: ClayColors.deepPurple),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Color(0xFFEDE5F8), height: 24),
            const SizedBox(height: 8),

            // Speech Rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Speech Rate',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: ClayColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDD2F5)),
                  ),
                  child: Text(
                    '${speechRate.toStringAsFixed(2)}x',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: ClayColors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                activeTrackColor: ClayColors.deepPurple,
                inactiveTrackColor: const Color(0xFFDDD2F5),
                thumbColor: ClayColors.deepPurple,
              ),
              child: Slider(
                min: 0.5,
                max: 2.0,
                divisions: 6,
                value: speechRate.clamp(0.5, 2.0),
                onChanged: onSpeechRateChanged,
              ),
            ),
            const SizedBox(height: 12),

            // Pitch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Voice Pitch',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: ClayColors.textDark,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDD2F5)),
                  ),
                  child: Text(
                    pitch.toStringAsFixed(2),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: ClayColors.deepPurple,
                    ),
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                activeTrackColor: ClayColors.deepPurple,
                inactiveTrackColor: const Color(0xFFDDD2F5),
                thumbColor: ClayColors.deepPurple,
              ),
              child: Slider(
                min: 0.5,
                max: 2.0,
                divisions: 6,
                value: pitch.clamp(0.5, 2.0),
                onChanged: onPitchChanged,
              ),
            ),
            const SizedBox(height: 20),

            // Voice selection button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: ClayColors.deepPurple,
                side: const BorderSide(color: Color(0xFFDDD2F5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.record_voice_over_rounded, color: ClayColors.deepPurple),
              label: Text(
                selectedVoice != null
                    ? (selectedVoice!['name'] ?? 'Custom Voice')
                    : 'Select Device Voice (${availableVoices.length} available)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: ClayColors.textDark,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                TtsVoiceSelectorSheet.show(
                  context,
                  voices: availableVoices,
                  selectedVoice: selectedVoice,
                  onVoiceSelected: onVoiceChanged,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

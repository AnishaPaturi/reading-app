import 'package:flutter/material.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TtsSettingsPanel(
        speechRate: speechRate,
        pitch: pitch,
        selectedVoice: selectedVoice,
        availableVoices: availableVoices,
        onSpeechRateChanged: onSpeechRateChanged,
        onPitchChanged: onPitchChanged,
        onVoiceChanged: onVoiceChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Speech Rate
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Speech Rate', style: theme.textTheme.bodyMedium),
                Text(
                  '${speechRate.toStringAsFixed(2)}x',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Slider(
              min: 0.5,
              max: 2.0,
              divisions: 6,
              value: speechRate.clamp(0.5, 2.0),
              onChanged: onSpeechRateChanged,
            ),
            const SizedBox(height: 8),

            // Pitch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Voice Pitch', style: theme.textTheme.bodyMedium),
                Text(
                  pitch.toStringAsFixed(2),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            Slider(
              min: 0.5,
              max: 2.0,
              divisions: 6,
              value: pitch.clamp(0.5, 2.0),
              onChanged: onPitchChanged,
            ),
            const SizedBox(height: 16),

            // Voice selection button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.record_voice_over_rounded),
              label: Text(
                selectedVoice != null
                    ? (selectedVoice!['name'] ?? 'Custom Voice')
                    : 'Select Device Voice (${availableVoices.length} available)',
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

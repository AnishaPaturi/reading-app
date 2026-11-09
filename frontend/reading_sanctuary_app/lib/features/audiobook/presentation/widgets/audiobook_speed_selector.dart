import 'package:flutter/material.dart';
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AudiobookSpeedSelector(
        currentSpeed: currentSpeed,
        onSpeedSelected: onSpeedSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Playback Speed',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AudioSettings.availableSpeeds.length,
                itemBuilder: (context, index) {
                  final speed = AudioSettings.availableSpeeds[index];
                  final isSelected = (speed - currentSpeed).abs() < 0.01;

                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                    title: Text('${speed}x'),
                    trailing: speed == 1.0
                        ? Text(
                            'Normal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        : null,
                    onTap: () {
                      onSpeedSelected(speed);
                      Navigator.pop(context);
                    },
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

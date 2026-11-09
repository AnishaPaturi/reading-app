import 'package:flutter/material.dart';

class AudiobookSleepTimerSheet extends StatelessWidget {
  final Duration? remainingTime;
  final bool endOfChapter;
  final void Function(Duration? duration, {bool endOfChapter}) onTimerSelected;

  const AudiobookSleepTimerSheet({
    super.key,
    required this.remainingTime,
    required this.endOfChapter,
    required this.onTimerSelected,
  });

  static void show(
    BuildContext context, {
    required Duration? remainingTime,
    required bool endOfChapter,
    required void Function(Duration? duration, {bool endOfChapter}) onTimerSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AudiobookSleepTimerSheet(
        remainingTime: remainingTime,
        endOfChapter: endOfChapter,
        onTimerSelected: onTimerSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final timerOptions = [
      {'label': 'Off', 'duration': null, 'endOfChapter': false},
      {'label': '5 minutes', 'duration': const Duration(minutes: 5), 'endOfChapter': false},
      {'label': '10 minutes', 'duration': const Duration(minutes: 10), 'endOfChapter': false},
      {'label': '15 minutes', 'duration': const Duration(minutes: 15), 'endOfChapter': false},
      {'label': '30 minutes', 'duration': const Duration(minutes: 30), 'endOfChapter': false},
      {'label': '45 minutes', 'duration': const Duration(minutes: 45), 'endOfChapter': false},
      {'label': '60 minutes', 'duration': const Duration(minutes: 60), 'endOfChapter': false},
      {'label': 'End of current chapter', 'duration': null, 'endOfChapter': true},
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sleep Timer',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (remainingTime != null)
                    Text(
                      '${remainingTime!.inMinutes}:${(remainingTime!.inSeconds % 60).toString().padLeft(2, '0')} remaining',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: timerOptions.length,
                itemBuilder: (context, index) {
                  final option = timerOptions[index];
                  final label = option['label'] as String;
                  final dur = option['duration'] as Duration?;
                  final isEoc = option['endOfChapter'] as bool;

                  final isSelected = isEoc
                      ? endOfChapter
                      : (dur == null && remainingTime == null && !endOfChapter);

                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                    title: Text(label),
                    onTap: () {
                      onTimerSelected(dur, endOfChapter: isEoc);
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: AudiobookSleepTimerSheet(
          remainingTime: remainingTime,
          endOfChapter: endOfChapter,
          onTimerSelected: onTimerSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sleep Timer',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ClayColors.textDark,
                    ),
                  ),
                  if (remainingTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7FE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDD2F5)),
                      ),
                      child: Text(
                        '${remainingTime!.inMinutes}:${(remainingTime!.inSeconds % 60).toString().padLeft(2, '0')} remaining',
                        style: GoogleFonts.inter(
                          color: ClayColors.deepPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(color: Color(0xFFEDE5F8), height: 24),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: timerOptions.length,
                itemBuilder: (context, index) {
                  final option = timerOptions[index];
                  final label = option['label'] as String;
                  final dur = option['duration'] as Duration?;
                  final isEoc = option['endOfChapter'] as bool;

                  final isSelected = isEoc
                      ? endOfChapter
                      : (dur == null && remainingTime == null && !endOfChapter);

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
                          label,
                          style: GoogleFonts.inter(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? ClayColors.deepPurple : ClayColors.textDark,
                            fontSize: 14.5,
                          ),
                        ),
                        onTap: () {
                          onTimerSelected(dur, endOfChapter: isEoc);
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

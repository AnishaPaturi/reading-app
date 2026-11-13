import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class TtsVoiceSelectorSheet extends StatelessWidget {
  final List<Map<String, String>> voices;
  final Map<String, String>? selectedVoice;
  final ValueChanged<Map<String, String>> onVoiceSelected;

  const TtsVoiceSelectorSheet({
    super.key,
    required this.voices,
    required this.selectedVoice,
    required this.onVoiceSelected,
  });

  static void show(
    BuildContext context, {
    required List<Map<String, String>> voices,
    required Map<String, String>? selectedVoice,
    required ValueChanged<Map<String, String>> onVoiceSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.88,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: TtsVoiceSelectorSheet(
            voices: voices,
            selectedVoice: selectedVoice,
            onVoiceSelected: onVoiceSelected,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Available Voices (${voices.length})',
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
          ),
          const Divider(color: Color(0xFFEDE5F8), height: 1),
          if (voices.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No additional device voices found',
                  style: GoogleFonts.inter(
                    color: ClayColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: voices.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final voice = voices[index];
                  final name = voice['name'] ?? 'Voice ${index + 1}';
                  final locale = voice['locale'] ?? '';
                  final isSelected = selectedVoice != null &&
                      selectedVoice!['name'] == voice['name'];

                  return Material(
                    color: isSelected ? const Color(0xFFFAF7FE) : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: isSelected ? const BorderSide(color: Color(0xFFDDD2F5)) : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.record_voice_over_outlined,
                        color: isSelected ? ClayColors.deepPurple : ClayColors.textMuted.withValues(alpha: 0.6),
                      ),
                      title: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? ClayColors.deepPurple : ClayColors.textDark,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: locale.isNotEmpty
                          ? Text(
                              locale,
                              style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
                            )
                          : null,
                      onTap: () {
                        onVoiceSelected(voice);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

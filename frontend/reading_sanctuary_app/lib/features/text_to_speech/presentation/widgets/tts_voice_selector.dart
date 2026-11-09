import 'package:flutter/material.dart';

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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => TtsVoiceSelectorSheet(
          voices: voices,
          selectedVoice: selectedVoice,
          onVoiceSelected: onVoiceSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          ),
          const Divider(height: 1),
          if (voices.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'No additional device voices found',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: voices.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final voice = voices[index];
                  final name = voice['name'] ?? 'Voice ${index + 1}';
                  final locale = voice['locale'] ?? '';
                  final isSelected = selectedVoice != null &&
                      selectedVoice!['name'] == voice['name'];

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor:
                        theme.colorScheme.primaryContainer.withAlpha(70),
                    leading: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.record_voice_over_outlined,
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                    title: Text(name),
                    subtitle: locale.isNotEmpty ? Text(locale) : null,
                    onTap: () {
                      onVoiceSelected(voice);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

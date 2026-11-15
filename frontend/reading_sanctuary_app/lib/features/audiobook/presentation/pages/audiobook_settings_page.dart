import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/audiobook_providers.dart';

class AudiobookSettingsPage extends ConsumerStatefulWidget {
  const AudiobookSettingsPage({super.key});

  @override
  ConsumerState<AudiobookSettingsPage> createState() => _AudiobookSettingsPageState();
}

class _AudiobookSettingsPageState extends ConsumerState<AudiobookSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    final playbackService = ref.watch(audiobookPlaybackServiceProvider);
    final settings = playbackService.settings;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Audiobook Settings',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? AppColors.ivory : AppColors.textDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSectionHeader('Playback Preferences', primary),
          Card(
            color: isDark ? AppColors.card : AppColors.parchment,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Default Speed'),
                  subtitle: const Text('Preferred playback speed for new books'),
                  trailing: DropdownButton<double>(
                    value: settings.playbackSpeed,
                    underline: const SizedBox(),
                    items: [0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
                        .map((s) => DropdownMenuItem(value: s, child: Text('${s}x')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        playbackService.setSpeed(val);
                        setState(() {});
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Auto Rewind on Resume'),
                  subtitle: const Text('Rewinds a few seconds after being paused'),
                  trailing: DropdownButton<int>(
                    value: settings.autoRewindSeconds,
                    underline: const SizedBox(),
                    items: [0, 3, 5, 10]
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s == 0 ? 'Off' : '$s sec')))
                        .toList(),
                    onChanged: (val) async {
                      if (val != null) {
                        final updated = settings.copyWith(autoRewindSeconds: val);
                        await ref.read(audiobookLocalDatasourceProvider).saveSettings(updated);
                        setState(() {});
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Skip Silence'),
                  subtitle: const Text('Skip sustained quiet portions between sections'),
                  value: settings.silenceSkipping,
                  activeColor: primary,
                  onChanged: (val) {
                    playbackService.setSilenceSkipping(val);
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Volume Boost'),
                  subtitle: const Text('Amplifies low-volume audiobook recordings safely'),
                  value: settings.volumeBoost,
                  activeColor: primary,
                  onChanged: (val) {
                    playbackService.setVolumeBoost(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Sleep & Night Mode', primary),
          Card(
            color: isDark ? AppColors.card : AppColors.parchment,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Shake to Extend'),
                  subtitle: const Text('Shake your phone when timer ends to add 5 minutes'),
                  value: settings.shakeToExtend,
                  activeColor: primary,
                  onChanged: (val) async {
                    final updated = settings.copyWith(shakeToExtend: val);
                    await ref.read(audiobookLocalDatasourceProvider).saveSettings(updated);
                    setState(() {});
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Night Appearance Default'),
                  subtitle: const Text('Use ultra-dim warm appearance while sleep timer is active'),
                  value: settings.nightAppearance,
                  activeColor: primary,
                  onChanged: (val) async {
                    final updated = settings.copyWith(nightAppearance: val);
                    await ref.read(audiobookLocalDatasourceProvider).saveSettings(updated);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Appearance & Accent', primary),
          Card(
            color: isDark ? AppColors.card : AppColors.parchment,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Player Accent Color'),
                  const SizedBox(height: 4),
                  const Text(
                    'Select a fixed accent color or choose dynamic cover palette (default).',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildColorChoice(null, 'Dynamic', Colors.grey, settings.customAccentColor == null),
                      const SizedBox(width: 8),
                      _buildColorChoice(0xFFD4AF37, 'Gold', const Color(0xFFD4AF37), settings.customAccentColor == 0xFFD4AF37),
                      const SizedBox(width: 8),
                      _buildColorChoice(0xFF8B5A2B, 'Bronze', const Color(0xFF8B5A2B), settings.customAccentColor == 0xFF8B5A2B),
                      const SizedBox(width: 8),
                      _buildColorChoice(0xFF4A7C59, 'Sage', const Color(0xFF4A7C59), settings.customAccentColor == 0xFF4A7C59),
                      const SizedBox(width: 8),
                      _buildColorChoice(0xFF8B0000, 'Crimson', const Color(0xFF8B0000), settings.customAccentColor == 0xFF8B0000),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildColorChoice(int? colorVal, String label, Color color, bool selected) {
    return InkWell(
      onTap: () async {
        final playback = ref.read(audiobookPlaybackServiceProvider);
        final updated = playback.settings.copyWith(
          customAccentColor: colorVal,
          clearCustomAccentColor: colorVal == null,
        );
        await ref.read(audiobookLocalDatasourceProvider).saveSettings(updated);
        setState(() {});
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.withOpacity(0.3), width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 6, backgroundColor: color),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

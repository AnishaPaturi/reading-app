import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../models/sync_models.dart';
import '../../providers/sync_providers.dart';

class SyncConflictCard extends ConsumerWidget {
  final SyncConflictItem conflict;

  const SyncConflictCard({
    super.key,
    required this.conflict,
  });

  String _formatPayload(String? raw) {
    if (raw == null || raw.isEmpty) return 'No content';
    try {
      final map = jsonDecode(raw);
      if (map is Map) {
        if (map.containsKey('title') || map.containsKey('content')) {
          final t = map['title'] ?? '';
          final c = map['content'] ?? '';
          return [if (t.isNotEmpty) 'Title: $t', if (c.isNotEmpty) 'Content: $c'].join('\n');
        }
        if (map.containsKey('pageNumber')) {
          return 'Page: ${map['pageNumber']}';
        }
      }
      return const JsonEncoder.withIndent('  ').convert(map);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(syncEngineProvider.notifier);

    return Card(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE8613C), width: 1.2),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.merge_type, color: Color(0xFFE8613C), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conflict on ${conflict.entityType}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8613C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    conflict.reason,
                    style: const TextStyle(color: Color(0xFFE8613C), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              conflict.message,
              style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.walnut,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Edits (Local)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.gold)),
                        const SizedBox(height: 6),
                        Text(
                          _formatPayload(conflict.localPayload),
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.walnut,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Server Version (v${conflict.serverVersion})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF4FA3D9))),
                        const SizedBox(height: 6),
                        Text(
                          _formatPayload(conflict.serverPayload),
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () {
                    engine.resolveConflict(conflict.clientChangeId, ConflictResolution.keepLocal);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kept local version and queued update')),
                    );
                  },
                  child: const Text('Keep My Changes'),
                ),
                OutlinedButton(
                  onPressed: () {
                    engine.resolveConflict(conflict.clientChangeId, ConflictResolution.keepServer);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Accepted server version')),
                    );
                  },
                  child: const Text('Keep Server Version'),
                ),
                TextButton(
                  onPressed: () {
                    engine.resolveConflict(conflict.clientChangeId, ConflictResolution.keepBoth);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kept both copies')),
                    );
                  },
                  child: const Text('Keep Both'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

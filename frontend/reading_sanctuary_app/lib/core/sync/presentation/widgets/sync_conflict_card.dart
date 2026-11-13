import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/clay_components.dart';
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

    return ClayCard(
      borderRadius: 20,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.merge_type_rounded, color: ClayColors.coral, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Conflict on ${conflict.entityType}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                    color: ClayColors.textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conflict.reason,
                  style: GoogleFonts.inter(
                    color: ClayColors.coral,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            conflict.message,
            style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD2F5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Edits (Local)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: ClayColors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatPayload(conflict.localPayload),
                        style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textDark),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7FE),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDDD2F5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Server Version (v${conflict.serverVersion})',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: const Color(0xFF4FA3D9),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatPayload(conflict.serverPayload),
                        style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textDark),
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
              ElevatedButton(
                onPressed: () {
                  engine.resolveConflict(conflict.clientChangeId, ConflictResolution.keepLocal);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kept local version and queued update')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ClayColors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: Text('Keep My Changes', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              OutlinedButton(
                onPressed: () {
                  engine.resolveConflict(conflict.clientChangeId, ConflictResolution.keepServer);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Accepted server version')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: ClayColors.deepPurple,
                  side: const BorderSide(color: Color(0xFFDDD2F5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: Text('Keep Server Version', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              TextButton(
                onPressed: () {
                  engine.resolveConflict(conflict.clientChangeId, ConflictResolution.keepBoth);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kept both copies')),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: ClayColors.textMuted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: Text('Keep Both', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

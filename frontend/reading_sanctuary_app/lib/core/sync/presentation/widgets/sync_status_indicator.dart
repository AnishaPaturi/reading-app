import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../models/sync_models.dart';
import '../../providers/sync_providers.dart';

class SyncStatusIndicator extends ConsumerWidget {
  final bool compact;

  const SyncStatusIndicator({
    super.key,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(syncStatusProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final conflicts = ref.watch(syncConflictsProvider);

    IconData icon;
    Color color;
    String tooltip;

    if (conflicts.isNotEmpty) {
      icon = Icons.warning_amber_rounded;
      color = const Color(0xFFE8613C);
      tooltip = '${conflicts.length} sync conflict(s) need resolution';
    } else {
      switch (status) {
        case SyncStatus.synced:
          icon = Icons.cloud_done_outlined;
          color = const Color(0xFF5CB89A);
          tooltip = 'All changes synced';
          break;
        case SyncStatus.syncing:
          icon = Icons.sync;
          color = AppColors.gold;
          tooltip = 'Syncing with cloud...';
          break;
        case SyncStatus.offline:
          icon = Icons.cloud_off_outlined;
          color = AppColors.textLightSecondary;
          tooltip = 'Offline - reading and saving locally';
          break;
        case SyncStatus.pendingChanges:
          icon = Icons.cloud_upload_outlined;
          color = const Color(0xFFE6A23C);
          tooltip = '$pendingCount changes queued for sync';
          break;
        case SyncStatus.error:
          icon = Icons.sync_problem_outlined;
          color = const Color(0xFFE05A7A);
          tooltip = 'Sync issue - tap to retry';
          break;
      }
    }

    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: status == SyncStatus.syncing
              ? RotationTransition(
                  turns: const AlwaysStoppedAnimation(0.25),
                  child: Icon(icon, color: color, size: 22),
                )
              : Icon(icon, color: color, size: 22),
          tooltip: tooltip,
          onPressed: () {
            if (conflicts.isNotEmpty || status == SyncStatus.error || status == SyncStatus.pendingChanges) {
              context.push('/sync/settings');
            } else {
              ref.read(syncEngineProvider.notifier).syncNow();
            }
          },
        ),
        if (pendingCount > 0 && conflicts.isEmpty)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE6A23C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                pendingCount > 99 ? '99+' : '$pendingCount',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (conflicts.isNotEmpty)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE8613C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conflicts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );

    if (compact) return content;

    return InkWell(
      onTap: () => context.push('/sync/settings'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              tooltip,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

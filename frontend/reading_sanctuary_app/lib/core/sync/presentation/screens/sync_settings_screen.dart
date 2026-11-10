import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../app/theme/app_colors.dart';
import '../../models/sync_models.dart';
import '../../providers/sync_providers.dart';
import '../widgets/sync_conflict_card.dart';

class SyncSettingsScreen extends ConsumerStatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  ConsumerState<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends ConsumerState<SyncSettingsScreen> {
  List<SyncDeviceModel> _devices = [];
  bool _loadingDevices = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loadingDevices = true);
    try {
      final api = ref.read(syncApiServiceProvider);
      final list = await api.listDevices();
      if (mounted) setState(() => _devices = list);
    } catch (_) {
      // Ignored if offline
    } finally {
      if (mounted) setState(() => _loadingDevices = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(syncStatusProvider);
    final engine = ref.watch(syncEngineProvider);
    final localDb = ref.watch(localStorageDbProvider);
    final conflicts = ref.watch(syncConflictsProvider);
    final lastSync = localDb.getLastSyncTime();
    final deviceId = localDb.getDeviceId() ?? 'Not registered';
    final deviceName = localDb.getDeviceName() ?? 'Current Device';
    final cursor = localDb.getLastSyncCursor();

    final timeFormatter = DateFormat.yMMMd().add_jms();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync & Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sync Now',
            onPressed: engine.isSyncing
                ? null
                : () async {
                    await engine.syncNow();
                    _loadDevices();
                  },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await engine.syncNow();
          await _loadDevices();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sync Status Header Card
                  Card(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.walnut,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              status == SyncStatus.synced
                                  ? Icons.cloud_done
                                  : (status == SyncStatus.syncing
                                      ? Icons.sync
                                      : (status == SyncStatus.offline
                                          ? Icons.cloud_off
                                          : Icons.cloud_upload)),
                              color: status == SyncStatus.synced
                                  ? const Color(0xFF5CB89A)
                                  : (status == SyncStatus.offline
                                      ? AppColors.textLightSecondary
                                      : AppColors.gold),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  status == SyncStatus.synced
                                      ? 'Synchronized'
                                      : (status == SyncStatus.syncing
                                          ? 'Synchronizing...'
                                          : (status == SyncStatus.offline
                                              ? 'Offline Mode'
                                              : 'Changes Pending Upload')),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lastSync != null
                                      ? 'Last synced: ${timeFormatter.format(lastSync)}'
                                      : 'Never synchronized',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textLightSecondary),
                                ),
                                if (engine.lastErrorMessage != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    engine.lastErrorMessage!,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFE05A7A)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: engine.isSyncing
                                ? null
                                : () async {
                                    await engine.syncNow();
                                    _loadDevices();
                                  },
                            icon: engine.isSyncing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.sync, size: 18),
                            label: Text(engine.isSyncing ? 'Syncing...' : 'Sync Now'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Active Conflicts Section
                  if (conflicts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFE8613C), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Conflicts Requiring Resolution (${conflicts.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final conflict in conflicts)
                      SyncConflictCard(conflict: conflict),
                  ],

                  // Outbox Queue Card
                  const SizedBox(height: 20),
                  Card(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pending Changes (Outbox)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textLight)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: engine.pendingCount > 0 ? const Color(0xFFE6A23C) : const Color(0xFF5CB89A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${engine.pendingCount} pending',
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (engine.pendingCount == 0)
                            const Text(
                              'All offline changes have been sent to the cloud.',
                              style: TextStyle(color: AppColors.textLightSecondary, fontSize: 13),
                            )
                          else
                            Text(
                              '${engine.pendingCount} reading position, bookmark, note or goal updates saved locally and queued for upload.',
                              style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Current Device Details Card
                  const SizedBox(height: 20),
                  Card(
                    color: AppColors.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('This Device',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textLight)),
                          const SizedBox(height: 12),
                          _DetailRow(label: 'Name', value: deviceName),
                          _DetailRow(label: 'Platform', value: engine.devicePlatform),
                          _DetailRow(label: 'Identifier', value: deviceId),
                          _DetailRow(label: 'Sync Cursor', value: '$cursor'),
                        ],
                      ),
                    ),
                  ),

                  // Other Devices List
                  const SizedBox(height: 24),
                  const Text('Registered Devices',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                  const SizedBox(height: 10),
                  if (_loadingDevices)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else if (_devices.isEmpty)
                    Card(
                      color: AppColors.card,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No other devices registered yet. Log in on another phone or computer to sync.',
                            style: TextStyle(color: AppColors.textLightSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final dev in _devices)
                      Card(
                        color: AppColors.card,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: Icon(
                            dev.platform == 'ANDROID'
                                ? Icons.phone_android
                                : (dev.platform == 'IOS' ? Icons.phone_iphone : Icons.laptop),
                            color: AppColors.gold,
                          ),
                          title: Text(dev.deviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            dev.lastSeenAt != null
                                ? 'Last seen ${timeFormatter.format(dev.lastSeenAt!)} · Cursor ${dev.lastSyncCursor}'
                                : 'Cursor ${dev.lastSyncCursor}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: dev.id == deviceId
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('Current',
                                      style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  tooltip: 'Deactivate device',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Deactivate Device'),
                                        content: Text('Remove "${dev.deviceName}" from your synced devices?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Deactivate')),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await ref.read(syncApiServiceProvider).deactivateDevice(dev.id);
                                      _loadDevices();
                                    }
                                  },
                                ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textLightSecondary, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

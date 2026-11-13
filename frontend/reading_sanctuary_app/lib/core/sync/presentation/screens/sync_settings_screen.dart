import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/clay_components.dart';
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
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : context.go('/settings'),
        ),
        title: Text(
          'Sync & Devices',
          style: GoogleFonts.inter(
            color: ClayColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: ClayColors.deepPurple),
            tooltip: 'Sync Now',
            onPressed: engine.isSyncing
                ? null
                : () async {
                    await engine.syncNow();
                    _loadDevices();
                  },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: ClayColors.deepPurple,
        onRefresh: () async {
          await engine.syncNow();
          await _loadDevices();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sync Status Header Card
                  ClayCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF7FE),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDDD2F5)),
                          ),
                          child: Icon(
                            status == SyncStatus.synced
                                ? Icons.cloud_done_rounded
                                : (status == SyncStatus.syncing
                                    ? Icons.sync_rounded
                                    : (status == SyncStatus.offline
                                        ? Icons.cloud_off_rounded
                                        : Icons.cloud_upload_rounded)),
                            color: status == SyncStatus.synced
                                ? const Color(0xFF2E9E67)
                                : (status == SyncStatus.offline
                                    ? ClayColors.textMuted
                                    : ClayColors.deepPurple),
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
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: ClayColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastSync != null
                                    ? 'Last synced: ${timeFormatter.format(lastSync)}'
                                    : 'Never synchronized',
                                style: GoogleFonts.inter(fontSize: 12.5, color: ClayColors.textMuted),
                              ),
                              if (engine.lastErrorMessage != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  engine.lastErrorMessage!,
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                                ),
                              ],
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: engine.isSyncing
                              ? null
                              : () async {
                                  await engine.syncNow();
                                  _loadDevices();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ClayColors.deepPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          icon: engine.isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.sync_rounded, size: 18, color: Colors.white),
                          label: Text(
                            engine.isSyncing ? 'Syncing...' : 'Sync Now',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active Conflicts Section
                  if (conflicts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: ClayColors.coral, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Conflicts Requiring Resolution (${conflicts.length})',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: ClayColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final conflict in conflicts)
                      SyncConflictCard(conflict: conflict),
                  ],

                  // Outbox Queue Card
                  const SizedBox(height: 18),
                  ClayCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pending Changes (Outbox)',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: ClayColors.textDark),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: engine.pendingCount > 0
                                    ? ClayColors.amber.withValues(alpha: 0.2)
                                    : const Color(0xFF2E9E67).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${engine.pendingCount} pending',
                                style: GoogleFonts.inter(
                                  color: engine.pendingCount > 0 ? const Color(0xFFB47814) : const Color(0xFF2E9E67),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (engine.pendingCount == 0)
                          Text(
                            'All offline changes have been sent to the cloud.',
                            style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13),
                          )
                        else
                          Text(
                            '${engine.pendingCount} reading position, bookmark, note or goal updates saved locally and queued for upload.',
                            style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13),
                          ),
                      ],
                    ),
                  ),

                  // Current Device Details Card
                  const SizedBox(height: 18),
                  ClayCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This Device',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: ClayColors.textDark),
                        ),
                        const SizedBox(height: 12),
                        _DetailRow(label: 'Name', value: deviceName),
                        _DetailRow(label: 'Platform', value: engine.devicePlatform),
                        _DetailRow(label: 'Identifier', value: deviceId),
                        _DetailRow(label: 'Sync Cursor', value: '$cursor'),
                      ],
                    ),
                  ),

                  // Other Devices List
                  const SizedBox(height: 24),
                  Text(
                    'Registered Devices',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: ClayColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  if (_loadingDevices)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: ClayColors.deepPurple)))
                  else if (_devices.isEmpty)
                    ClayCard(
                      padding: const EdgeInsets.all(22),
                      child: Center(
                        child: Text(
                          'No other devices registered yet. Log in on another phone or computer to sync.',
                          style: GoogleFonts.inter(color: ClayColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    for (final dev in _devices)
                      ClayCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7FE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDDD2F5)),
                            ),
                            child: Icon(
                              dev.platform == 'ANDROID'
                                  ? Icons.phone_android_rounded
                                  : (dev.platform == 'IOS' ? Icons.phone_iphone_rounded : Icons.laptop_rounded),
                              color: ClayColors.deepPurple,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            dev.deviceName,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ClayColors.textDark, fontSize: 14),
                          ),
                          subtitle: Text(
                            dev.lastSeenAt != null
                                ? 'Last seen ${timeFormatter.format(dev.lastSeenAt!)} · Cursor ${dev.lastSyncCursor}'
                                : 'Cursor ${dev.lastSyncCursor}',
                            style: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
                          ),
                          trailing: dev.id == deviceId
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: ClayColors.lavender.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: GoogleFonts.inter(color: ClayColors.deepPurple, fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                                  tooltip: 'Deactivate device',
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        title: Text('Deactivate Device', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
                                        content: Text('Remove "${dev.deviceName}" from your synced devices?', style: GoogleFonts.inter()),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: Text('Cancel', style: GoogleFonts.inter(color: ClayColors.textMuted)),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            ),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: Text('Deactivate', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
                                          ),
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
          Text(label, style: GoogleFonts.inter(color: ClayColors.textMuted, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.inter(color: ClayColors.textDark, fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

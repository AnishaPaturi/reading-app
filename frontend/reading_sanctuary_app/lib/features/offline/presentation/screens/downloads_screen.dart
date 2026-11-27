import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/sync/providers/sync_providers.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/utils/book_file_navigation.dart';
import '../../domain/models/download_task.dart';
import '../../services/download_manager.dart';
import '../../services/downloads_scanner_service.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  final bool autoScanOnMount;

  const DownloadsScreen({
    super.key,
    this.autoScanOnMount = true,
  });

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  String _formatFilter = 'All';
  bool _hasInitialScanned = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoScanOnMount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasInitialScanned && mounted) {
          _hasInitialScanned = true;
          _triggerScan();
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = val.trim();
        });
      }
    });
  }

  Future<void> _triggerScan() async {
    final scanner = ref.read(downloadsScannerServiceProvider);
    await scanner.scanDownloadsFolder();
  }

  void _showRemovalDialog(DownloadTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Remove Download',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose how to remove "${task.bookTitle}":',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ClayColors.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ClayColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ClayColors.clayBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: ClayColors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Removing from Downloads will NOT remove this book from your main library or delete your reading progress and bookmarks.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.35,
                        color: ClayColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.playlist_remove_rounded,
                  color: ClayColors.deepPurple),
              title: Text(
                'Remove from Downloads only',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.textDark,
                ),
              ),
              subtitle: Text(
                'Keep original physical file on your device storage',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: ClayColors.textMuted,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final manager = ref.read(downloadManagerProvider);
                await manager.removeDownload(task.fileId,
                    deletePhysicalFile: false);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Removed "${task.bookTitle}" from Downloads list'),
                    ),
                  );
                }
              },
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_forever_rounded,
                  color: Colors.redAccent),
              title: Text(
                'Delete file from device storage',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
              subtitle: Text(
                'Permanently delete the local copy to free storage space',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: ClayColors.textMuted,
                ),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final manager = ref.read(downloadManagerProvider);
                final success = await manager.removeDownload(task.fileId,
                    deletePhysicalFile: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Deleted "${task.bookTitle}" file from storage'
                            : 'Could not delete file: permission or storage error',
                      ),
                      backgroundColor:
                          success ? ClayColors.deepPurple : Colors.redAccent,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: ClayColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(downloadManagerProvider);
    final scanner = ref.watch(downloadsScannerServiceProvider);
    final sortOption = ref.watch(downloadsSortOptionProvider);

    final activeTasks = manager.getActiveDownloads();
    final recentlyDownloaded = manager.getRecentlyDownloadedBooks(
      limit: 15,
      sort: sortOption,
    );
    final allDownloads = manager.getAllDownloadsFiltered(
      sort: sortOption,
      searchQuery: _searchQuery,
      formatFilter: _formatFilter,
    );

    final scanResult = scanner.lastResult;
    final totalBytes = manager.calculateTotalStorageBytes();
    final totalFormatted = _formatBytes(totalBytes);

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/library'),
        ),
        title: Text(
          'Downloads',
          style: GoogleFonts.inter(
            color: ClayColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: scanner.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ClayColors.deepPurple,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: ClayColors.deepPurple),
            tooltip: 'Scan Downloads Folder',
            onPressed: scanner.isScanning ? null : _triggerScan,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _triggerScan,
        color: ClayColors.deepPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top summary banner
                  _buildSummaryBanner(
                    totalBooks: allDownloads.length,
                    storageFormatted: totalFormatted,
                    activeCount: activeTasks.length,
                  ),
                  const SizedBox(height: 16),

                  // Permission / Access error banner if present
                  if (scanResult != null && scanResult.isPermissionDenied)
                    _buildPermissionDeniedCard(scanResult),

                  // 1. ACTIVE DOWNLOADS SECTION (Feature 5)
                  if (activeTasks.isNotEmpty) ...[
                    _buildSectionHeader(
                      title: 'Active Downloads',
                      badge: '${activeTasks.length}',
                      badgeColor: ClayColors.amber,
                    ),
                    const SizedBox(height: 8),
                    ...activeTasks.map((t) => _buildActiveDownloadCard(t, manager)),
                    const SizedBox(height: 24),
                  ],

                  // 2. RECENTLY DOWNLOADED SECTION (Feature 1)
                  _buildSectionHeader(
                    title: 'Recently Downloaded',
                    subtitle: 'Books downloaded through the app',
                    badge: recentlyDownloaded.isNotEmpty
                        ? '${recentlyDownloaded.length}'
                        : null,
                    badgeColor: ClayColors.softLilac,
                  ),
                  const SizedBox(height: 10),
                  if (recentlyDownloaded.isEmpty)
                    _buildRecentlyEmptyState()
                  else
                    _buildRecentlyDownloadedList(recentlyDownloaded),
                  const SizedBox(height: 28),

                  // 3. ALL DOWNLOADS SECTION (Features 2, 3, 4, 6)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildSectionHeader(
                          title: 'All Downloads',
                          subtitle: 'Downloaded and discovered books on device',
                          badge: '${allDownloads.length}',
                        ),
                      ),
                      _buildSortDropdown(sortOption),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search bar and Format Filters
                  _buildSearchAndFilters(),
                  const SizedBox(height: 16),

                  if (allDownloads.isEmpty)
                    _buildAllDownloadsEmptyState(scanner.isScanning)
                  else
                    ...allDownloads.map((t) => _buildDownloadItemTile(t)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBanner({
    required int totalBooks,
    required String storageFormatted,
    required int activeCount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ClayColors.deepPurple.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClayColors.softLilac.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder_special_rounded,
              color: ClayColors.deepPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalBooks Available Offline',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: ClayColors.textDark,
                  ),
                ),
                Text(
                  '$storageFormatted storage used on device',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ClayColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (activeCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ClayColors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ClayColors.amberDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$activeCount downloading',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: ClayColors.amberDark,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ClayColors.textDark,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? ClayColors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ClayColors.deepPurple,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: ClayColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPermissionDeniedCard(DownloadsScanResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD1C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_off_rounded, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Storage Access Required',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: ClayColors.textDark,
                  ),
                ),
                Text(
                  'Allow storage access to discover books stored in your Downloads directory.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ClayColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.deepPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onPressed: _triggerScan,
            child: const Text('Grant',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDownloadCard(DownloadTask task, DownloadManager manager) {
    final percent = (task.progress * 100).toInt();
    final downloadedMB = (task.downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMB = task.totalBytes > 0
        ? (task.totalBytes / (1024 * 1024)).toStringAsFixed(1)
        : '?';

    final isPaused = task.isPaused;
    final isFailed = task.isFailed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ClayColors.deepPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.format.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ClayColors.deepPurple,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.bookTitle,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: ClayColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Controls
              if (isFailed)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent),
                  tooltip: 'Retry',
                  onPressed: () => manager.resumeDownload(task.fileId),
                )
              else if (isPaused)
                IconButton(
                  icon: const Icon(Icons.play_arrow_rounded,
                      color: ClayColors.deepPurple),
                  tooltip: 'Resume',
                  onPressed: () => manager.resumeDownload(task.fileId),
                )
              else
                IconButton(
                  icon: const Icon(Icons.pause_rounded,
                      color: ClayColors.deepPurple),
                  tooltip: 'Pause',
                  onPressed: () => manager.pauseDownload(task.fileId),
                ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: ClayColors.textMuted),
                tooltip: 'Cancel',
                onPressed: () => manager.cancelDownload(task.fileId),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: task.totalBytes > 0 ? task.progress : null,
              minHeight: 6,
              backgroundColor: const Color(0xFFEFE9F8),
              valueColor: AlwaysStoppedAnimation<Color>(
                isFailed
                    ? Colors.redAccent
                    : isPaused
                        ? ClayColors.amberDark
                        : ClayColors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFailed
                    ? 'Download failed'
                    : isPaused
                        ? 'Paused'
                        : '$percent% ($downloadedMB MB of $totalMB MB)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isFailed ? Colors.redAccent : ClayColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (task.errorMessage != null && isFailed)
                Expanded(
                  child: Text(
                    task.errorMessage!,
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.redAccent),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClayColors.clayBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 36, color: ClayColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'No recently downloaded books',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: ClayColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Books you download through the app will appear here with cover and timestamp.',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: ClayColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyDownloadedList(List<DownloadTask> tasks) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final task = tasks[index];
          final dateStr = task.downloadedAt != null
              ? DateFormat.MMMd().add_jm().format(task.downloadedAt!)
              : 'Recently';

          return GestureDetector(
            onTap: () => openDownloadedBook(context, task),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ClayColors.deepPurple.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Book Spine / Cover Mock
                  Container(
                    width: 50,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7E57C2), Color(0xFF512DA8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        task.format.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          task.bookTitle,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: ClayColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.author != null && task.author!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.author!,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ClayColors.textMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded,
                                size: 12, color: ClayColors.deepPurple),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dateStr,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: ClayColors.deepPurple,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortDropdown(DownloadsSortOption current) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClayColors.clayBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DownloadsSortOption>(
          value: current,
          icon: const Icon(Icons.sort_rounded, size: 18, color: ClayColors.deepPurple),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: ClayColors.textDark,
          ),
          onChanged: (val) {
            if (val != null) {
              ref.read(downloadsSortOptionProvider.notifier).state = val;
            }
          },
          items: const [
            DropdownMenuItem(
              value: DownloadsSortOption.newestFirst,
              child: Text('Newest First'),
            ),
            DropdownMenuItem(
              value: DownloadsSortOption.oldestFirst,
              child: Text('Oldest First'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textDark),
            decoration: InputDecoration(
              hintText: 'Search downloads by title or author...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, color: ClayColors.textMuted, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Format Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ['All', 'EPUB', 'PDF', 'DOCX', 'TXT', 'Audio']
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f),
                        selected: _formatFilter == f,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _formatFilter = f;
                            });
                          }
                        },
                        selectedColor: ClayColors.deepPurple,
                        backgroundColor: Colors.white,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _formatFilter == f ? Colors.white : ClayColors.textDark,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _formatFilter == f
                                ? ClayColors.deepPurple
                                : ClayColors.clayBorder,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadItemTile(DownloadTask task) {
    final formatUpper = task.format.toUpperCase();
    final isAudio =
        formatUpper == 'MP3' || formatUpper == 'M4B' || formatUpper == 'M4A';

    final effectiveDate = task.effectiveTimestamp;
    final dateStr = effectiveDate != null
        ? DateFormat.yMMMd().format(effectiveDate)
        : null;

    final isDiscovered = task.isDiscovered;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          onTap: () => openDownloadedBook(context, task),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isAudio
                  ? ClayColors.amber.withValues(alpha: 0.25)
                  : ClayColors.softLilac.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                isAudio ? Icons.headphones_rounded : Icons.auto_stories_rounded,
                color: isAudio ? ClayColors.amberDark : ClayColors.deepPurple,
                size: 22,
              ),
            ),
          ),
          title: Text(
            task.bookTitle,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: ClayColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.author != null && task.author!.isNotEmpty)
                Text(
                  task.author!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ClayColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Format Tag
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: ClayColors.clayBorder.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.format.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: ClayColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Source Tag: Downloaded vs Downloads Folder
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDiscovered
                          ? ClayColors.mint.withValues(alpha: 0.3)
                          : ClayColors.softLilac.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isDiscovered ? 'Downloads Folder' : 'Downloaded',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDiscovered
                            ? ClayColors.mintDark
                            : ClayColors.deepPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.formattedSize,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: ClayColors.textMuted,
                    ),
                  ),
                  if (dateStr != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '• $dateStr',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ClayColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: ClayColors.textMuted),
            tooltip: 'Options',
            onPressed: () => _showRemovalDialog(task),
          ),
        ),
      ),
    );
  }

  Widget _buildAllDownloadsEmptyState(bool isScanning) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Icon(
            isScanning
                ? Icons.sync_rounded
                : Icons.file_download_off_rounded,
            size: 48,
            color: ClayColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            isScanning
                ? 'Scanning Downloads folder...'
                : 'No downloaded books found',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: ClayColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isScanning
                ? 'Looking for supported ebooks and audiobooks on your device.'
                : 'Books downloaded from the library or placed in your device Downloads folder will appear here.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: ClayColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isScanning) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayColors.deepPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              label: const Text('Scan Downloads Folder',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              onPressed: _triggerScan,
            ),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../home/presentation/widgets/reader_sidebar.dart';
import '../../models/batch_import_state.dart';
import '../../models/classified_book.dart';
import '../../providers/book_discovery_providers.dart';
import '../../providers/book_selection_provider.dart';
import '../../services/discovery_engine.dart';
import '../widgets/batch_import_progress_panel.dart';
import '../widgets/discovered_book_card.dart';
import '../widgets/discovery_summary_card.dart';
import '../widgets/folder_management_section.dart';

enum DiscoveryFilterTab {
  all,
  readyToImport,
  inLibrary,
  duplicates,
  issues,
}

class DiscoverBooksScreen extends ConsumerStatefulWidget {
  const DiscoverBooksScreen({super.key});

  @override
  ConsumerState<DiscoverBooksScreen> createState() => _DiscoverBooksScreenState();
}

class _DiscoverBooksScreenState extends ConsumerState<DiscoverBooksScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DiscoveryFilterTab _activeTab = DiscoveryFilterTab.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndScanIfNeeded();
    });
  }

  Future<void> _initAndScanIfNeeded() async {
    final folderManager = ref.read(folderManagerServiceProvider);
    if (!folderManager.isInitialized) {
      await folderManager.initialize();
    }
  }

  Future<void> _runScan() async {
    // Deselect all items on new scan to prevent stale references
    ref.read(bookSelectionProvider.notifier).deselectAll();
    final engine = ref.read(discoveryEngineProvider);
    await engine.runDiscovery();
  }

  Future<void> _addFolder() async {
    final folderManager = ref.read(folderManagerServiceProvider);
    final added = await folderManager.pickAndRegisterFolder();
    if (added != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registered folder: ${added.name}'),
          backgroundColor: ClayColors.deepPurple,
        ),
      );
      // Automatically scan after adding a new folder
      await _runScan();
    }
  }

  Future<void> _removeFolder(String folderId) async {
    final folderManager = ref.read(folderManagerServiceProvider);
    await folderManager.removeFolder(folderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan folder removed'),
          backgroundColor: ClayColors.deepPurple,
        ),
      );
    }
  }

  List<ClassifiedBook> _filterBooks(List<ClassifiedBook> books) {
    return switch (_activeTab) {
      DiscoveryFilterTab.all => books,
      DiscoveryFilterTab.readyToImport => books.where((b) => b.isImportable).toList(),
      DiscoveryFilterTab.inLibrary => books.where((b) => b.isAlreadyImported).toList(),
      DiscoveryFilterTab.duplicates => books.where((b) => b.isDuplicateInScan).toList(),
      DiscoveryFilterTab.issues => books.where((b) => b.hasError).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final folderManager = ref.watch(folderManagerServiceProvider);
    final engine = ref.watch(discoveryEngineProvider);
    final selectedKeys = ref.watch(bookSelectionProvider);
    final selectionNotifier = ref.read(bookSelectionProvider.notifier);
    final batchImportState = ref.watch(batchImportProvider);
    final batchImportNotifier = ref.read(batchImportProvider.notifier);

    final allBooks = engine.classifiedBooks;
    final filteredBooks = _filterBooks(allBooks);
    final eligibleCount = engine.newBooks.length;
    final selectedBytes = selectionNotifier.getSelectedTotalBytes(allBooks);
    final isScanning = engine.progress.phase == DiscoveryEnginePhase.scanning ||
        engine.progress.phase == DiscoveryEnginePhase.processingAndHashing ||
        engine.progress.phase == DiscoveryEnginePhase.checkingDuplicates;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF4F0FB),
          drawer: isWide
              ? null
              : Drawer(
                  width: 220,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: ReaderSidebar(
                    width: 220,
                    activeRoute: '/library',
                    onItemTapped: () => Navigator.of(context).pop(),
                  ),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWide) const ReaderSidebar(activeRoute: '/library'),
                Expanded(
                  child: Column(
                    children: [
                      // Top App Bar
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isWide ? 28 : 16,
                          16,
                          isWide ? 28 : 16,
                          8,
                        ),
                        child: _buildTopBar(
                          context,
                          isWide,
                          isScanning,
                          allBooks.isNotEmpty,
                        ),
                      ),

                      // Main Content Scrollable
                      Expanded(
                        child: RefreshIndicator(
                          color: ClayColors.deepPurple,
                          onRefresh: _runScan,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 28 : 16,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Batch Import Progress Panel (if active or has results)
                                if (batchImportState.status != BatchImportStatus.idle) ...[
                                  BatchImportProgressPanel(
                                    importState: batchImportState,
                                    onCancel: () => batchImportNotifier.cancelImport(),
                                    onRetryFailed: () => batchImportNotifier.retryFailed(),
                                    onDismiss: () => batchImportNotifier.reset(),
                                    onViewLibrary: () => context.go('/library'),
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                // Folder Management Collapsible Card
                                FolderManagementSection(
                                  folderManager: folderManager,
                                  onAddFolder: _addFolder,
                                  onRemoveFolder: _removeFolder,
                                ),
                                const SizedBox(height: 14),

                                // Scanning In-Progress Feedback
                                if (isScanning) ...[
                                  _buildScanningIndicator(engine.progress),
                                  const SizedBox(height: 14),
                                ],

                                // Discovery Summary Statistics Card
                                if (!isScanning && allBooks.isNotEmpty) ...[
                                  DiscoverySummaryCard(
                                    totalCount: allBooks.length,
                                    newCount: engine.newBooks.length,
                                    alreadyImportedCount: engine.alreadyImportedBooks.length,
                                    duplicateInScanCount: engine.duplicateInScanBooks.length,
                                    unverifiedCount: engine.unverifiedBooks.length,
                                    invalidOrErrorCount: engine.invalidOrErrorBooks.length,
                                    onRetryVerification: engine.unverifiedBooks.isNotEmpty
                                        ? () => engine.retryVerification()
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                ],

                                // Selection Toolbar & Action Bar (when eligible books exist)
                                if (!isScanning && allBooks.isNotEmpty) ...[
                                  _buildSelectionBar(
                                    eligibleCount: eligibleCount,
                                    selectedCount: selectedKeys.length,
                                    selectedBytes: selectedBytes,
                                    isImporting: batchImportState.isImporting,
                                    onSelectAll: () => selectionNotifier.selectAllEligible(allBooks),
                                    onDeselectAll: () => selectionNotifier.deselectAll(),
                                    onImport: () {
                                      final selectedBooks = selectionNotifier.getSelectedBooks(allBooks);
                                      if (selectedBooks.isNotEmpty) {
                                        batchImportNotifier.startImport(selectedBooks);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Filter Tabs Bar
                                  _buildFilterTabs(allBooks, engine),
                                  const SizedBox(height: 12),
                                ],

                                // Discovered Books List or Empty State
                                if (isScanning)
                                  const SizedBox.shrink()
                                else if (allBooks.isEmpty)
                                  _buildEmptyState(folderManager.folders.isEmpty)
                                else if (filteredBooks.isEmpty)
                                  _buildEmptyTabState()
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredBooks.length,
                                    itemBuilder: (context, index) {
                                      final book = filteredBooks[index];
                                      final isSelected = selectedKeys.contains(book.file.pathOrUri);

                                      return DiscoveredBookCard(
                                        book: book,
                                        isSelected: isSelected,
                                        onSelectChanged: (_) {
                                          selectionNotifier.toggle(book);
                                        },
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: isWide
              ? null
              : const SafeArea(
                  top: false,
                  child: ClayBottomNav(activeRoute: '/library'),
                ),
        );
      },
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    bool isWide,
    bool isScanning,
    bool hasDiscovered,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: ClayColors.textDark),
              tooltip: 'Back to Library',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/library');
                }
              },
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Discover Books',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: ClayColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Automatic local book discovery & import',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ClayColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: isScanning ? null : _runScan,
          icon: isScanning
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.sync_rounded, size: 18, color: Colors.white),
          label: Text(
            isScanning ? 'Scanning...' : (hasDiscovered ? 'Scan Again' : 'Scan Folders'),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: ClayColors.deepPurple,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildScanningIndicator(DiscoveryEngineProgress progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDD2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: ClayColors.deepPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  progress.statusMessage,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ClayColors.textDark,
                  ),
                ),
              ),
              if (progress.totalFiles > 0)
                Text(
                  '${progress.processedFiles}/${progress.totalFiles}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ClayColors.textMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.progressPercent > 0 ? progress.progressPercent : null,
              minHeight: 6,
              backgroundColor: const Color(0xFFEDE5F8),
              valueColor: const AlwaysStoppedAnimation<Color>(ClayColors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar({
    required int eligibleCount,
    required int selectedCount,
    required int selectedBytes,
    required bool isImporting,
    required VoidCallback onSelectAll,
    required VoidCallback onDeselectAll,
    required VoidCallback onImport,
  }) {
    final formatBytesStr = BookSelectionNotifier.formatBytes(selectedBytes);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBFA)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              TextButton(
                onPressed: eligibleCount > 0 ? onSelectAll : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Select All ($eligibleCount)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: eligibleCount > 0 ? ClayColors.deepPurple : ClayColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('•', style: GoogleFonts.inter(color: ClayColors.softLilac)),
              const SizedBox(width: 8),
              TextButton(
                onPressed: selectedCount > 0 ? onDeselectAll : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Deselect All',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: selectedCount > 0 ? ClayColors.textDark : ClayColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: selectedCount > 0 && !isImporting ? onImport : null,
            icon: const Icon(Icons.file_download_outlined, size: 16, color: Colors.white),
            label: Text(
              selectedCount > 0
                  ? 'Import ($selectedCount • $formatBytesStr)'
                  : 'Import Selected',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.deepPurple,
              disabledBackgroundColor: const Color(0xFFC7B2F0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<ClassifiedBook> allBooks, DiscoveryEngine engine) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All (${allBooks.length})', DiscoveryFilterTab.all),
          const SizedBox(width: 6),
          _buildFilterChip('Ready to Import (${engine.newBooks.length})', DiscoveryFilterTab.readyToImport),
          const SizedBox(width: 6),
          _buildFilterChip('In Library (${engine.alreadyImportedBooks.length})', DiscoveryFilterTab.inLibrary),
          const SizedBox(width: 6),
          _buildFilterChip('Duplicates (${engine.duplicateInScanBooks.length})', DiscoveryFilterTab.duplicates),
          const SizedBox(width: 6),
          _buildFilterChip('Issues (${engine.invalidOrErrorBooks.length + engine.unverifiedBooks.length})', DiscoveryFilterTab.issues),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DiscoveryFilterTab tab) {
    final isActive = _activeTab == tab;

    return InkWell(
      onTap: () {
        setState(() {
          _activeTab = tab;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? ClayColors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? ClayColors.deepPurple : const Color(0xFFEADBFA),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : ClayColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool noFolders) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEADBFA)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF7F4FB),
              shape: BoxShape.circle,
            ),
            child: Icon(
              noFolders ? Icons.folder_open_rounded : Icons.menu_book_rounded,
              color: ClayColors.deepPurple,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            noFolders ? 'No Folders Registered' : 'Ready to Discover Books',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ClayColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noFolders
                ? 'Add a directory on your device using the "Add Folder" button above to start scanning for books.'
                : 'Tap "Scan Folders" above to search your registered folders for EPUB, PDF, and audiobooks.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: ClayColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: noFolders ? _addFolder : _runScan,
            icon: Icon(noFolders ? Icons.add_rounded : Icons.search_rounded, size: 18, color: Colors.white),
            label: Text(
              noFolders ? 'Add Scan Folder' : 'Start Scan Now',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEADBFA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.filter_list_off_rounded, color: ClayColors.softLilac, size: 36),
          const SizedBox(height: 12),
          Text(
            'No books match the selected category.',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textDark),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              setState(() {
                _activeTab = DiscoveryFilterTab.all;
              });
            },
            child: Text(
              'Show All Books',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ClayColors.deepPurple),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../providers/audiobook_library_provider.dart';
import '../providers/audiobook_providers.dart';
import '../widgets/audiobook_cover.dart';
import '../../services/audiobook_scanner_service.dart';
import '../../services/audiobook_duplicate_detection_service.dart';
import '../../utils/audiobook_duration_utils.dart';

class AudiobookImportPage extends ConsumerStatefulWidget {
  const AudiobookImportPage({super.key});

  @override
  ConsumerState<AudiobookImportPage> createState() => _AudiobookImportPageState();
}

class _AudiobookImportPageState extends ConsumerState<AudiobookImportPage> {
  bool _isScanning = false;
  String? _statusMessage;
  String? _warningMessage;
  List<DiscoveredBook> _discoveredBooks = [];
  List<AudiobookDuplicateEntry> _duplicateEntries = [];
  List<RejectedAudioFile> _rejectedFiles = [];

  Future<void> _pickFiles() async {
    final importService = ref.read(audiobookImportServiceProvider);

    setState(() {
      _isScanning = true;
      _statusMessage = 'Selecting audio files...';
      _warningMessage = null;
    });

    try {
      final pickResult = await importService.pickAudioFilesDetailed();

      if (!mounted) return;

      if (pickResult.wasCancelled) {
        setState(() {
          _isScanning = false;
          _statusMessage = null;
        });
        return;
      }

      final pickerRejected = <RejectedAudioFile>[];
      for (final name in pickResult.unsupportedFiles) {
        pickerRejected.add(RejectedAudioFile(
          fileName: name,
          filePath: name,
          reason: RejectedFileReason.unsupportedFormat,
        ));
      }
      for (final name in pickResult.inaccessibleFiles) {
        pickerRejected.add(RejectedAudioFile(
          fileName: name,
          filePath: name,
          reason: RejectedFileReason.inaccessible,
        ));
      }

      if (pickResult.isEmpty) {
        setState(() {
          _isScanning = false;
          _statusMessage = null;
          _rejectedFiles = pickerRejected;
          _warningMessage = 'No valid audio files selected. Supported formats: MP3, M4B, M4A, OGG, OPUS.';
        });
        return;
      }

      setState(() => _statusMessage = 'Reading metadata and grouping tracks...');

      final scanResult = await importService.previewPickedFiles(pickResult.validFiles);

      if (!mounted) return;

      setState(() => _statusMessage = 'Checking for existing library duplicates...');
      final duplicateService = ref.read(audiobookDuplicateDetectionServiceProvider);
      final entries = await duplicateService.checkDuplicates(discoveredBooks: scanResult.books);

      if (!mounted) return;

      final allRejected = [...pickerRejected, ...scanResult.rejectedFiles];
      String? issueNotice;
      if (allRejected.isNotEmpty) {
        issueNotice = '${allRejected.length} file(s) were skipped or rejected.';
      }

      setState(() {
        _discoveredBooks = scanResult.books;
        _duplicateEntries = entries;
        _rejectedFiles = allRejected;
        _isScanning = false;
        _statusMessage = null;
        _warningMessage = issueNotice;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusMessage = null;
        _warningMessage = 'Error scanning files: $e';
      });
    }
  }

  Future<void> _pickFolder() async {
    final importService = ref.read(audiobookImportServiceProvider);

    setState(() {
      _isScanning = true;
      _statusMessage = 'Selecting folder...';
      _warningMessage = null;
    });

    try {
      final folderPath = await importService.pickAudiobookFolder();

      if (!mounted) return;

      if (folderPath == null) {
        setState(() {
          _isScanning = false;
          _statusMessage = null;
        });
        return;
      }

      setState(() => _statusMessage = 'Scanning folder and subfolders...');

      final scanResult = await importService.previewFolderScan(folderPath);

      if (!mounted) return;

      if (scanResult.books.isEmpty) {
        setState(() {
          _discoveredBooks = [];
          _duplicateEntries = [];
          _rejectedFiles = scanResult.rejectedFiles;
          _isScanning = false;
          _statusMessage = null;
          _warningMessage = scanResult.hasRejectedFiles
              ? 'No audiobooks found. ${scanResult.rejectedFiles.length} file(s) were rejected.'
              : 'No supported audio files found in selected folder. Supported formats: MP3, M4B, M4A, OGG, OPUS.';
        });
        return;
      }

      setState(() => _statusMessage = 'Checking for existing library duplicates...');
      final duplicateService = ref.read(audiobookDuplicateDetectionServiceProvider);
      final entries = await duplicateService.checkDuplicates(discoveredBooks: scanResult.books);

      if (!mounted) return;

      String? issueNotice;
      if (scanResult.hasRejectedFiles) {
        issueNotice = '${scanResult.rejectedFiles.length} file(s) in folder were skipped (unsupported or invalid).';
      }

      setState(() {
        _discoveredBooks = scanResult.books;
        _duplicateEntries = entries;
        _rejectedFiles = scanResult.rejectedFiles;
        _isScanning = false;
        _statusMessage = null;
        _warningMessage = issueNotice;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusMessage = null;
        _warningMessage = 'Error scanning folder: $e';
      });
    }
  }

  Future<void> _commitImport() async {
    if (_discoveredBooks.isEmpty || _duplicateEntries.isEmpty) return;

    // Check if any duplicate book is missing an explicit decision
    final missingDecision = _duplicateEntries.where((e) => e.result.isDuplicate && e.action == null).toList();
    if (missingDecision.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please choose an action (Skip, Import Anyway, or Replace) for "${missingDecision.first.book.title}".'),
          backgroundColor: const Color(0xFFD9480F),
        ),
      );
      return;
    }

    final importService = ref.read(audiobookImportServiceProvider);

    setState(() {
      _isScanning = true;
      _statusMessage = 'Saving audiobooks to sanctuary...';
      _warningMessage = null;
    });

    try {
      final result = await importService.commitImportedBooks(entries: _duplicateEntries);
      await ref.read(audiobookLibraryProvider.notifier).refresh();

      if (!mounted) return;

      if (result.hasErrors) {
        setState(() {
          _isScanning = false;
          _statusMessage = null;
          _warningMessage = 'Import completed with errors:\n${result.errors.join('\n')}';
        });
        return;
      }

      final successMsg = StringBuffer();
      if (result.importedBooks.isNotEmpty) {
        successMsg.write('Imported ${result.importedBooks.length}');
      }
      if (result.replacedBooks.isNotEmpty) {
        if (successMsg.isNotEmpty) successMsg.write(', ');
        successMsg.write('Replaced ${result.replacedBooks.length}');
      }
      if (result.skippedBooks.isNotEmpty) {
        if (successMsg.isNotEmpty) successMsg.write(', ');
        successMsg.write('Skipped ${result.skippedBooks.length}');
      }
      successMsg.write(' audiobook(s)!');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMsg.toString()),
          backgroundColor: ClayColors.primaryPurple,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusMessage = null;
        _warningMessage = 'Failed to save imported books: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1B1527) : ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Import Audiobooks',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: isDark ? Colors.white : ClayColors.textDark,
          ),
        ),
      ),
      body: _isScanning
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: ClayColors.primaryPurple),
                    const SizedBox(height: 20),
                    Text(
                      _statusMessage ?? 'Processing...',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : ClayColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Source Selection Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF271E38) : ClayColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white12 : ClayColors.clayBorder,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ClayColors.deepPurple.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ClayColors.primaryPurple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.library_music_rounded, color: ClayColors.primaryPurple, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Select Audio Source',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : ClayColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Import your own DRM-free audiobooks. Supported audio formats: MP3, M4B, M4A, OGG, OPUS.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : ClayColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ClayColors.primaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 2,
                                ),
                                icon: const Icon(Icons.folder_open_rounded, size: 20),
                                label: Text(
                                  'Scan Folder',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                                ),
                                onPressed: _pickFolder,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white : ClayColors.textDark,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: ClayColors.primaryPurple, width: 1.4),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.audio_file_rounded, size: 20, color: ClayColors.primaryPurple),
                                label: Text(
                                  'Pick Files',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                                ),
                                onPressed: _pickFiles,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Warning or Info Message
                  if (_warningMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFEEBA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF856404), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _warningMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF856404),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF856404)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(() => _warningMessage = null),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Skipped / Rejected Files Details Card
                  if (_rejectedFiles.isNotEmpty) ...[
                    _buildRejectedFilesCard(isDark),
                  ],

                  // Discovered Audiobooks Preview
                  if (_discoveredBooks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Proposed Audiobooks (${_discoveredBooks.length})',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : ClayColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _discoveredBooks.clear();
                            _duplicateEntries.clear();
                            _rejectedFiles.clear();
                          }),
                          child: Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              color: ClayColors.primaryPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _discoveredBooks.length,
                      itemBuilder: (context, index) {
                        return _buildDiscoveredBookCard(index, isDark);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClayColors.primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      onPressed: _commitImport,
                      child: Text(
                        'Import ${_discoveredBooks.length} Audiobook(s)',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDiscoveredBookCard(int index, bool isDark) {
    final entry = index < _duplicateEntries.length
        ? _duplicateEntries[index]
        : AudiobookDuplicateEntry(
            book: _discoveredBooks[index],
            result: const DuplicateCheckResult(status: DuplicateStatus.none),
          );
    final book = entry.book;
    final dupResult = entry.result;
    final selectedAction = entry.action;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF271E38) : ClayColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dupResult.isDuplicate
              ? (dupResult.isExactMatch ? const Color(0xFFE03131) : const Color(0xFFFD7E14))
              : (isDark ? Colors.white12 : ClayColors.clayBorder),
          width: dupResult.isDuplicate ? 1.6 : 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AudiobookCover(
                  coverPath: book.coverPath,
                  title: book.title,
                  author: book.author,
                  width: 64,
                  height: 64,
                  borderRadius: 10,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : ClayColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: ClayColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${book.tracks.length} track(s) · ${AudiobookDurationUtils.formatDurationHuman(Duration(milliseconds: book.totalDurationMs))}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : ClayColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: ClayColors.primaryPurple),
                  tooltip: 'Edit details',
                  onPressed: () => _editBookDetails(index),
                ),
              ],
            ),

            // Duplicate Detection Banner and Action Controls
            if (dupResult.isDuplicate) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: dupResult.isExactMatch
                      ? (isDark ? const Color(0xFF381A1A) : const Color(0xFFFFF0F0))
                      : (isDark ? const Color(0xFF302012) : const Color(0xFFFFF7ED)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dupResult.isExactMatch
                        ? (isDark ? const Color(0xFF8B2C2C) : const Color(0xFFFFC9C9))
                        : (isDark ? const Color(0xFF7C4A1E) : const Color(0xFFFFD8A8)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          dupResult.isExactMatch ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                          size: 16,
                          color: dupResult.isExactMatch ? const Color(0xFFE03131) : const Color(0xFFE8590C),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          dupResult.isExactMatch ? 'Exact File Match' : 'Possible Duplicate',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: dupResult.isExactMatch ? const Color(0xFFE03131) : const Color(0xFFE8590C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Existing library match: ${dupResult.existingBookTitle ?? "Unknown"}'
                      '${dupResult.existingAuthor != null ? " by ${dupResult.existingAuthor}" : ""}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dupResult.isExactMatch
                          ? '${dupResult.matchingFilePaths.length} identical track path(s) already in library.'
                          : 'Same normalized title and author.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : ClayColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Choose an action:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : ClayColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('Skip'),
                          selected: selectedAction == DuplicateAction.skip,
                          selectedColor: const Color(0xFFFA5252).withValues(alpha: 0.2),
                          onSelected: (val) {
                            setState(() {
                              _duplicateEntries[index] = entry.copyWith(
                                action: val ? DuplicateAction.skip : null,
                              );
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Import Anyway'),
                          selected: selectedAction == DuplicateAction.importAnyway,
                          selectedColor: ClayColors.primaryPurple.withValues(alpha: 0.2),
                          onSelected: (val) {
                            setState(() {
                              _duplicateEntries[index] = entry.copyWith(
                                action: val ? DuplicateAction.importAnyway : null,
                              );
                            });
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Replace'),
                          selected: selectedAction == DuplicateAction.replace,
                          selectedColor: const Color(0xFFFD7E14).withValues(alpha: 0.2),
                          onSelected: (val) {
                            if (val) {
                              _confirmReplace(index, isDark);
                            } else {
                              setState(() {
                                _duplicateEntries[index] = entry.copyWith(action: null);
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF2B8A3E)),
                  const SizedBox(width: 4),
                  Text(
                    'Ready to import',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF2B8A3E), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Track list (${book.tracks.length})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ClayColors.primaryPurple,
                  ),
                ),
                children: book.tracks.map((t) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 8),
                    leading: Text(
                      '${t.trackOrder}.',
                      style: const TextStyle(fontSize: 11, color: ClayColors.textMuted),
                    ),
                    title: Text(
                      t.chapterTitle ?? t.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : ClayColors.textDark,
                      ),
                    ),
                    trailing: Text(
                      AudiobookDurationUtils.formatDuration(Duration(milliseconds: t.durationMs)),
                      style: const TextStyle(fontSize: 11, color: ClayColors.textMuted),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReplace(int index, bool isDark) {
    final entry = _duplicateEntries[index];
    final title = entry.result.existingBookTitle ?? entry.book.title;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF271E38) : ClayColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFD9480F)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Replace Existing Audiobook?',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Text(
          'Replacing "$title" will update its audio tracks and metadata while keeping its library identity.\n\n'
          'Listening progress will be reset.\n\n'
          'Original audio files on disk will not be deleted.',
          style: GoogleFonts.inter(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: ClayColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9480F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _duplicateEntries[index] = entry.copyWith(action: DuplicateAction.replace);
              });
            },
            child: const Text('Confirm Replace'),
          ),
        ],
      ),
    );
  }

  void _editBookDetails(int index) {
    final book = _discoveredBooks[index];
    final titleCtrl = TextEditingController(text: book.title);
    final authorCtrl = TextEditingController(text: book.author);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: ClayColors.cardBg,
          title: Text(
            'Edit Book Details',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ClayColors.textDark),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: authorCtrl,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: ClayColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayColors.primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                setState(() {
                  book.title = titleCtrl.text.trim();
                  book.author = authorCtrl.text.trim();
                });
                Navigator.pop(ctx);

                // Re-evaluate duplicates after detail edit
                final duplicateService = ref.read(audiobookDuplicateDetectionServiceProvider);
                final updatedEntries = await duplicateService.checkDuplicates(discoveredBooks: _discoveredBooks);
                if (mounted) {
                  setState(() {
                    _duplicateEntries = updatedEntries;
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRejectedFilesCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2218) : const Color(0xFFFFF9F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF6B4A28) : const Color(0xFFFFD8A8),
          width: 1.2,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE67700).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD9480F), size: 20),
          ),
          title: Text(
            'Skipped / Rejected Files (${_rejectedFiles.length})',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFFFC078) : const Color(0xFFD9480F),
            ),
          ),
          subtitle: Text(
            'Files that could not be processed as audio tracks',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? Colors.white60 : ClayColors.textMuted,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _rejectedFiles.length,
                separatorBuilder: (_, __) => Divider(
                  height: 12,
                  color: isDark ? Colors.white10 : const Color(0xFFFFE8CC),
                ),
                itemBuilder: (context, index) {
                  final file = _rejectedFiles[index];
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3, right: 8),
                        child: Icon(Icons.block_rounded, size: 14, color: Color(0xFFD9480F)),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : ClayColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              file.reasonLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFFF922B) : const Color(0xFFE67700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

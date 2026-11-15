import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/audiobook_library_provider.dart';
import '../providers/audiobook_providers.dart';
import '../widgets/audiobook_cover.dart';
import '../../services/audiobook_scanner_service.dart';
import '../../utils/audiobook_duration_utils.dart';

class AudiobookImportPage extends ConsumerStatefulWidget {
  const AudiobookImportPage({super.key});

  @override
  ConsumerState<AudiobookImportPage> createState() => _AudiobookImportPageState();
}

class _AudiobookImportPageState extends ConsumerState<AudiobookImportPage> {
  bool _isScanning = false;
  String? _statusMessage;
  List<DiscoveredBook> _discoveredBooks = [];

  Future<void> _pickFiles() async {
    final importService = ref.read(audiobookImportServiceProvider);
    setState(() {
      _isScanning = true;
      _statusMessage = 'Selecting audio files...';
    });

    try {
      final files = await importService.pickAudioFiles();
      if (files.isEmpty) {
        setState(() {
          _isScanning = false;
          _statusMessage = null;
        });
        return;
      }

      setState(() => _statusMessage = 'Reading metadata and grouping tracks...');
      final discovered = await importService.previewPickedFiles(files);
      setState(() {
        _discoveredBooks = discovered;
        _isScanning = false;
        _statusMessage = null;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error scanning files: $e';
      });
    }
  }

  Future<void> _pickFolder() async {
    final importService = ref.read(audiobookImportServiceProvider);
    setState(() {
      _isScanning = true;
      _statusMessage = 'Selecting folder...';
    });

    try {
      final folderPath = await importService.pickAudiobookFolder();
      if (folderPath == null) {
        setState(() {
          _isScanning = false;
          _statusMessage = null;
        });
        return;
      }

      setState(() => _statusMessage = 'Scanning folder and subfolders...');
      final discovered = await importService.previewFolderScan(folderPath);
      setState(() {
        _discoveredBooks = discovered;
        _isScanning = false;
        _statusMessage = null;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Error scanning folder: $e';
      });
    }
  }

  Future<void> _commitImport() async {
    if (_discoveredBooks.isEmpty) return;

    final importService = ref.read(audiobookImportServiceProvider);
    setState(() {
      _isScanning = true;
      _statusMessage = 'Saving audiobooks to sanctuary...';
    });

    try {
      await importService.commitImportedBooks(_discoveredBooks);
      await ref.read(audiobookLibraryProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported ${_discoveredBooks.length} audiobook(s)!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = 'Failed to save imported books: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = isDark ? AppColors.gold : AppColors.brown;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Import Audiobooks',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? AppColors.ivory : AppColors.textDark,
          ),
        ),
      ),
      body: _isScanning
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primary),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage ?? 'Processing...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? AppColors.ivory : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pick Options Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.card : AppColors.parchment,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Audio Source',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.ivory : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bring your own DRM-free audiobooks. All common formats supported: MP3, M4B, M4A, OGG, OPUS.',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: isDark ? AppColors.espresso : AppColors.ivory,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.folder_open_rounded),
                                label: const Text('Scan Folder'),
                                onPressed: _pickFolder,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? AppColors.ivory : AppColors.textDark,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.audio_file_rounded),
                                label: const Text('Pick Files'),
                                onPressed: _pickFiles,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (_statusMessage != null && !_isScanning) ...[
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  if (_discoveredBooks.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Proposed Audiobooks (${_discoveredBooks.length})',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.ivory : AppColors.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _discoveredBooks.clear()),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _discoveredBooks.length,
                      itemBuilder: (context, index) {
                        return _buildDiscoveredBookCard(index, primary, isDark);
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: isDark ? AppColors.espresso : AppColors.ivory,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _commitImport,
                      child: Text(
                        'Import ${_discoveredBooks.length} Audiobook(s)',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildDiscoveredBookCard(int index, Color primary, bool isDark) {
    final book = _discoveredBooks[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      color: isDark ? AppColors.card : AppColors.parchment,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  borderRadius: 8,
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
                          color: isDark ? AppColors.ivory : AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark ? AppColors.gold : AppColors.brown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${book.tracks.length} track(s) · ${AudiobookDurationUtils.formatDurationHuman(Duration(milliseconds: book.totalDurationMs))}',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit details',
                  onPressed: () => _editBookDetails(index),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  'Track list (${book.tracks.length})',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: primary),
                ),
                children: book.tracks.map((t) {
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 8),
                    leading: Text(
                      '${t.trackOrder}.',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    title: Text(
                      t.chapterTitle ?? t.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      AudiobookDurationUtils.formatDuration(Duration(milliseconds: t.durationMs)),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  void _editBookDetails(int index) {
    final book = _discoveredBooks[index];
    final titleCtrl = TextEditingController(text: book.title);
    final authorCtrl = TextEditingController(text: book.author);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Book Details'),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  book.title = titleCtrl.text.trim();
                  book.author = authorCtrl.text.trim();
                });
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

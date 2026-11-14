import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_import_provider.dart';

class BookImportScreen extends ConsumerStatefulWidget {
  final PlatformFile selectedFile;
  final String? shelfId;

  const BookImportScreen({
    super.key,
    required this.selectedFile,
    this.shelfId,
  });

  @override
  ConsumerState<BookImportScreen> createState() => _BookImportScreenState();
}

class _BookImportScreenState extends ConsumerState<BookImportScreen> {
  late final TextEditingController titleController;
  late final TextEditingController authorController;

  String readingStatus = 'UNREAD';

  @override
  void initState() {
    super.initState();

    final filename = widget.selectedFile.name;
    final title = filename.contains('.')
        ? filename.substring(0, filename.lastIndexOf('.'))
        : filename;

    final cleanTitle = title
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .trim();

    titleController = TextEditingController(text: cleanTitle);
    authorController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    authorController.dispose();
    super.dispose();
  }

  String formatSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _mapReadingStatusToApi(String status) {
    switch (status) {
      case 'READING':
        return 'CURRENTLY_READING';
      case 'COMPLETED':
        return 'COMPLETED';
      case 'UNREAD':
      default:
        return 'WANT_TO_READ';
    }
  }

  Future<void> _handleImport() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a book title')),
      );
      return;
    }

    final author = authorController.text.trim();
    final notifier = ref.read(bookImportProvider.notifier);

    final book = await notifier.importBook(
      file: widget.selectedFile,
      title: title,
      author: author.isNotEmpty ? author : 'Unknown Author',
      readingStatus: _mapReadingStatusToApi(readingStatus),
      shelfId: widget.shelfId,
    );

    if (book != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${book.title}" successfully added to your Sanctuary!'),
          backgroundColor: const Color(0xFF2E9E67),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(bookImportProvider.notifier).reset();
      Navigator.of(context).pop(book);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final importState = ref.watch(bookImportProvider);
    final isImporting = importState.status == BookImportStatus.uploading ||
        importState.status == BookImportStatus.processing;

    final format = widget.selectedFile.extension?.toUpperCase() ?? '';
    final isAudio = format == 'MP3' || format == 'M4A' || format == 'M4B';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Import Book',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Selected File Preview Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isAudio
                          ? Icons.headphones_outlined
                          : Icons.menu_book_outlined,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.selectedFile.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      '$format • ${formatSize(widget.selectedFile.size)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Progress Banner when uploading
            if (isImporting) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBF8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCD2F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          importState.status == BookImportStatus.processing
                              ? 'Processing metadata...'
                              : 'Uploading file...',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4C3364),
                          ),
                        ),
                        Text(
                          '${(importState.uploadProgress * 100).toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6550C7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: importState.status == BookImportStatus.processing
                            ? null
                            : importState.uploadProgress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE2DCF0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6550C7)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please keep the application open while the upload completes.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF7A6894),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Error Banner
            if (importState.status == BookImportStatus.failure &&
                importState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE8E8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF8B4B4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFC81E1E), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        importState.errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFFC81E1E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Title field
            TextField(
              controller: titleController,
              enabled: !isImporting,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Book Title',
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Author field
            TextField(
              controller: authorController,
              enabled: !isImporting,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: isAudio ? 'Author / Narrator' : 'Author',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Reading Status
            DropdownButtonFormField<String>(
              value: readingStatus,
              decoration: InputDecoration(
                labelText: 'Reading Status',
                prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'UNREAD',
                  child: Text('Want to Read'),
                ),
                DropdownMenuItem(
                  value: 'READING',
                  child: Text('Currently Reading'),
                ),
                DropdownMenuItem(
                  value: 'COMPLETED',
                  child: Text('Completed'),
                ),
              ],
              onChanged: isImporting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          readingStatus = value;
                        });
                      }
                    },
            ),

            const SizedBox(height: 28),

            // Add to My Library Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isImporting ? null : _handleImport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6550C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                icon: isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.library_add),
                label: Text(
                  isImporting ? 'Importing Book...' : 'Add to My Library',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

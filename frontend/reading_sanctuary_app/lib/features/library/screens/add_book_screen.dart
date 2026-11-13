import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';
import '../../authentication/presentation/widgets/clay_button.dart';
import '../data/models/book_metadata.dart';
import '../presentation/providers/book_upload_provider.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  const AddBookScreen({super.key});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController(text: '300');
  final _descController = TextEditingController();
  final _durationController = TextEditingController();

  String _selectedGenre = 'Fiction';
  ReadingStatus _status = ReadingStatus.wantToRead;
  int _selectedColorIndex = 0;
  bool _manualMode = false;
  bool _isSavingManual = false;

  final List<List<Color>> _colorPalettes = const [
    [Color(0xFF9482E6), Color(0xFF6550C7)],
    [Color(0xFF2B3A55), Color(0xFF111A2B)],
    [Color(0xFFB5651D), Color(0xFF5E3210)],
    [Color(0xFF7A2E3B), Color(0xFF3A1219)],
    [Color(0xFF2F5D50), Color(0xFF12302A)],
    [Color(0xFF5B2A5E), Color(0xFF22102A)],
    [Color(0xFFE08E79), Color(0xFFC7624C)],
  ];

  final List<String> _commonGenres = const [
    'Fiction',
    'Non-Fiction',
    'Fantasy',
    'Sci-Fi',
    'Romance',
    'Thriller',
    'Self-Help',
    'Mystery',
    'Classics',
    'Finance',
    'Audiobook',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _descController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _syncMetadataToControllers(BookMetadata metadata) {
    if (metadata.title != null && metadata.title!.isNotEmpty) {
      _titleController.text = metadata.title!;
    }
    if (metadata.author != null && metadata.author!.isNotEmpty) {
      _authorController.text = metadata.author!;
    }
    if (metadata.description != null && metadata.description!.isNotEmpty) {
      _descController.text = metadata.description!;
    }
    if (metadata.pages != null && metadata.pages! > 0) {
      _pagesController.text = metadata.pages.toString();
    }
    if (metadata.durationSeconds != null && metadata.durationSeconds! > 0) {
      final minutes = (metadata.durationSeconds! / 60).round();
      _durationController.text = '$minutes mins';
    }
    if (metadata.genre != null && metadata.genre!.isNotEmpty) {
      final match = _commonGenres.firstWhere(
        (g) => g.toLowerCase() == metadata.genre!.toLowerCase(),
        orElse: () => _selectedGenre,
      );
      _selectedGenre = match;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _readingStatusToApiString(ReadingStatus status) {
    return switch (status) {
      ReadingStatus.currentlyReading => 'CURRENTLY_READING',
      ReadingStatus.completed => 'COMPLETED',
      ReadingStatus.onHold => 'ON_HOLD',
      ReadingStatus.dnf => 'DNF',
      ReadingStatus.wantToRead || ReadingStatus.toRead => 'WANT_TO_READ',
    };
  }

  Future<void> _handleConfirmUpload() async {
    if (!_formKey.currentState!.validate()) return;

    final uploadNotifier = ref.read(bookUploadProvider.notifier);
    final currentMetadata = ref.read(bookUploadProvider).metadata;

    if (currentMetadata == null) return;

    // Update metadata from edited text controllers
    final editedMetadata = currentMetadata.copyWith(
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      genre: _selectedGenre,
      description: _descController.text.trim(),
      pages: int.tryParse(_pagesController.text.trim()),
    );
    uploadNotifier.updateMetadata(editedMetadata);

    final confirmedBook = await uploadNotifier.confirmAndSaveBook(
      readingStatus: _readingStatusToApiString(_status),
    );

    if (confirmedBook != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${confirmedBook.title}" added to your bookshelf!'),
          backgroundColor: const Color(0xFF2E9E67),
          behavior: SnackBarBehavior.floating,
        ),
      );
      ref.read(bookUploadProvider.notifier).reset();
      context.pop();
    }
  }

  Future<void> _handleManualSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingManual = true);

    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final pages = int.tryParse(_pagesController.text.trim()) ?? 250;
    final description = _descController.text.trim();

    final newBook = Book(
      id: 'book-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      author: author,
      genre: _selectedGenre,
      description: description.isNotEmpty ? description : 'A wonderful addition to your reading sanctuary.',
      status: _status,
      progress: _status == ReadingStatus.completed ? 1.0 : (_status == ReadingStatus.currentlyReading ? 0.05 : 0.0),
      pages: pages,
      formats: const [BookFormat.ebook],
      files: const [],
      addedAt: DateTime.now(),
      coverColors: _colorPalettes[_selectedColorIndex],
    );

    try {
      await ref.read(booksProvider.notifier).addBook(newBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$title" added to your library!'),
            backgroundColor: const Color(0xFF2E9E67),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _isSavingManual = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(bookUploadProvider);

    ref.listen<BookUploadState>(bookUploadProvider, (prev, next) {
      if (prev?.status != BookUploadStatus.readyForReview &&
          next.status == BookUploadStatus.readyForReview &&
          next.metadata != null) {
        _syncMetadataToControllers(next.metadata!);
      }
    });

    final isUploading = uploadState.status == BookUploadStatus.uploading ||
        uploadState.status == BookUploadStatus.extracting;

    final isReviewing = uploadState.status == BookUploadStatus.readyForReview ||
        uploadState.status == BookUploadStatus.saving;

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ClayColors.textDark, size: 20),
          onPressed: () {
            ref.read(bookUploadProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Text(
          isReviewing ? 'Review Book Details' : 'Add New Book',
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ClayColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: isUploading
              ? _buildUploadingView(uploadState)
              : (isReviewing
                  ? _buildReviewAndEditView(uploadState)
                  : (_manualMode ? _buildManualEntryView() : _buildUploadFirstView(uploadState))),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 1: UPLOAD FIRST STATE
  // ==========================================
  Widget _buildUploadFirstView(BookUploadState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          "Let's add something wonderful to your library.",
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: ClayColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Upload Card
        ClayCard(
          borderRadius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Icon Circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9482E6), Color(0xFF6550C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6550C7).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 20),

              Text(
                'Upload your book',
                style: GoogleFonts.fraunces(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a file from your device',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: ClayColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Supported Formats Pills
              Wrap(
                spacing: 8,
                children: const [
                  _FormatBadge(label: 'PDF', icon: Icons.picture_as_pdf_rounded),
                  _FormatBadge(label: 'EPUB', icon: Icons.book_rounded),
                  _FormatBadge(label: 'MP3', icon: Icons.headphones_rounded),
                  _FormatBadge(label: 'M4B', icon: Icons.audio_file_rounded),
                ],
              ),
              const SizedBox(height: 18),

              Text(
                'You can review and edit all detected details.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7A6894),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Choose a File Button
              ClayButton(
                label: 'Choose a file',
                onPressed: () => ref.read(bookUploadProvider.notifier).pickAndScanBook(),
              ),

              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF8B4B4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFC81E1E), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFC81E1E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 28),

        // How it works card
        ClayCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How it works',
                style: GoogleFonts.fraunces(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.textDark,
                ),
              ),
              const SizedBox(height: 14),
              _buildStepRow('1', 'Upload your book file', 'PDF, EPUB, MP3, or M4B'),
              const SizedBox(height: 12),
              _buildStepRow('2', 'We automatically identify the book', 'Title, author, cover, pages, duration'),
              const SizedBox(height: 12),
              _buildStepRow('3', 'Review and modify the details', 'Personalize status, genre, and reading notes'),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Manual entry toggle
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _manualMode = true),
            icon: const Icon(Icons.edit_note_rounded, color: ClayColors.deepPurple, size: 20),
            label: Text(
              'Or enter details manually',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: ClayColors.deepPurple,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStepRow(String number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: ClayColors.lavenderDark.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: ClayColors.deepPurple),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: ClayColors.textDark),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: ClayColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 2: UPLOADING / SCANNING STATE
  // ==========================================
  Widget _buildUploadingView(BookUploadState state) {
    final fileName = state.selectedFile?.name ?? 'Book File';
    final fileSize = state.selectedFile != null ? _formatFileSize(state.selectedFile!.size) : '';
    final isExtracting = state.status == BookUploadStatus.extracting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        ClayCard(
          borderRadius: 28,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EBF8),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      color: ClayColors.deepPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                isExtracting ? 'Analyzing Book Metadata...' : 'Uploading Book...',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                isExtracting
                    ? 'Scanning chapters, cover art, author, and reading stats'
                    : '$fileName ($fileSize)',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: ClayColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: isExtracting ? null : state.uploadProgress,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFEADBFA),
                  valueColor: const AlwaysStoppedAnimation<Color>(ClayColors.deepPurple),
                ),
              ),
              const SizedBox(height: 28),

              TextButton(
                onPressed: () => ref.read(bookUploadProvider.notifier).reset(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E3A3A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 3: REVIEW & EDIT EXTRACTED DETAILS
  // ==========================================
  Widget _buildReviewAndEditView(BookUploadState state) {
    final metadata = state.metadata;
    final isSaving = state.status == BookUploadStatus.saving;
    final file = state.selectedFile;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Attached File Header Banner
          if (file != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE4DBF2)),
              ),
              child: Row(
                children: [
                  _FormatBadge(
                    label: (metadata?.format ?? file.extension ?? 'FILE').toUpperCase(),
                    icon: (file.extension?.toLowerCase() == 'mp3' || file.extension?.toLowerCase() == 'm4b')
                        ? Icons.headphones_rounded
                        : Icons.menu_book_rounded,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: ClayColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatFileSize(file.size),
                          style: GoogleFonts.inter(fontSize: 11.5, color: ClayColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(bookUploadProvider.notifier).pickAndScanBook(),
                    child: Text(
                      'Replace',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Book Cover Preview
          Center(
            child: _buildCoverPreview(metadata?.coverBase64),
          ),
          const SizedBox(height: 24),

          // Title
          _buildLabel('Book Title *'),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: ClayColors.textDark),
            decoration: _inputDecoration('Book Title', Icons.book_outlined),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
          ),
          const SizedBox(height: 16),

          // Author
          _buildLabel('Author *'),
          TextFormField(
            controller: _authorController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: ClayColors.textDark),
            decoration: _inputDecoration('Author name', Icons.person_outline_rounded),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter author name' : null,
          ),
          const SizedBox(height: 16),

          // Genre
          _buildLabel('Genre'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonGenres.map((g) {
              final isSel = _selectedGenre == g;
              return ChoiceChip(
                label: Text(g),
                selected: isSel,
                onSelected: (val) {
                  if (val) setState(() => _selectedGenre = g);
                },
                selectedColor: ClayColors.deepPurple,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? Colors.white : ClayColors.textDark,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isSel ? ClayColors.deepPurple : const Color(0xFFE2DCF0)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Status & Pages/Duration row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Reading Status'),
                    DropdownButtonFormField<ReadingStatus>(
                      isExpanded: true,
                      value: _status,
                      decoration: _inputDecoration(null, Icons.auto_stories_rounded),
                      items: const [
                        DropdownMenuItem(value: ReadingStatus.wantToRead, child: Text('Want to Read')),
                        DropdownMenuItem(value: ReadingStatus.currentlyReading, child: Text('Currently Reading')),
                        DropdownMenuItem(value: ReadingStatus.completed, child: Text('Completed')),
                        DropdownMenuItem(value: ReadingStatus.dnf, child: Text('DNF')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(metadata?.durationSeconds != null ? 'Duration' : 'Pages'),
                    TextFormField(
                      controller: metadata?.durationSeconds != null ? _durationController : _pagesController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        metadata?.durationSeconds != null ? 'Mins' : 'Pages',
                        metadata?.durationSeconds != null ? Icons.timer_rounded : Icons.menu_book_rounded,
                      ),
                      validator: (v) {
                        if (metadata?.durationSeconds == null) {
                          final num = int.tryParse(v?.trim() ?? '');
                          if (num == null || num <= 0) return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cover theme selection
          _buildLabel('Cover Theme Palette'),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colorPalettes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSel = _selectedColorIndex == index;
                final colors = _colorPalettes[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? ClayColors.deepPurple : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSel ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Description
          _buildLabel('Description / Notes (Optional)'),
          TextFormField(
            controller: _descController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 13.5),
            decoration: _inputDecoration('Summary, notes, or thoughts...', Icons.notes_rounded),
          ),
          const SizedBox(height: 28),

          // Add to Bookshelf Button
          ClayButton(
            label: 'Add to My Bookshelf',
            isLoading: isSaving,
            onPressed: _handleConfirmUpload,
          ),
          const SizedBox(height: 14),

          // Cancel Action
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(bookUploadProvider.notifier).reset();
              },
              child: Text(
                'Cancel and Choose Another File',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: ClayColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCoverPreview(String? coverBase64) {
    if (coverBase64 != null && coverBase64.isNotEmpty) {
      try {
        final cleanData = coverBase64.contains(',') ? coverBase64.split(',')[1] : coverBase64;
        final bytes = base64Decode(cleanData.trim());
        return Container(
          width: 110,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        );
      } catch (_) {}
    }

    final colors = _colorPalettes[_selectedColorIndex];
    return Container(
      width: 110,
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          Text(
            _titleController.text.isNotEmpty ? _titleController.text : 'Book Title',
            style: GoogleFonts.fraunces(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _authorController.text.isNotEmpty ? _authorController.text : 'Author',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 4: MANUAL ENTRY VIEW (FALLBACK)
  // ==========================================
  Widget _buildManualEntryView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _manualMode = false),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to File Upload'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Center(child: _buildCoverPreview(null)),
          const SizedBox(height: 20),

          _buildLabel('Book Title *'),
          TextFormField(
            controller: _titleController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: ClayColors.textDark),
            decoration: _inputDecoration('Enter book title', Icons.book_outlined),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter the book title' : null,
          ),
          const SizedBox(height: 16),

          _buildLabel('Author *'),
          TextFormField(
            controller: _authorController,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: ClayColors.textDark),
            decoration: _inputDecoration('Enter author name', Icons.person_outline_rounded),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter the author name' : null,
          ),
          const SizedBox(height: 16),

          _buildLabel('Genre'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonGenres.map((g) {
              final isSel = _selectedGenre == g;
              return ChoiceChip(
                label: Text(g),
                selected: isSel,
                onSelected: (val) {
                  if (val) setState(() => _selectedGenre = g);
                },
                selectedColor: ClayColors.deepPurple,
                labelStyle: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? Colors.white : ClayColors.textDark,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isSel ? ClayColors.deepPurple : const Color(0xFFE2DCF0)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Initial Status'),
                    DropdownButtonFormField<ReadingStatus>(
                      isExpanded: true,
                      value: _status,
                      decoration: _inputDecoration(null, Icons.auto_stories_rounded),
                      items: const [
                        DropdownMenuItem(value: ReadingStatus.wantToRead, child: Text('Want to Read')),
                        DropdownMenuItem(value: ReadingStatus.currentlyReading, child: Text('Currently Reading')),
                        DropdownMenuItem(value: ReadingStatus.completed, child: Text('Completed')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Pages'),
                    TextFormField(
                      controller: _pagesController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Total pages', Icons.menu_book_rounded),
                      validator: (v) {
                        final num = int.tryParse(v?.trim() ?? '');
                        if (num == null || num <= 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildLabel('Cover Theme'),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colorPalettes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final isSel = _selectedColorIndex == index;
                final colors = _colorPalettes[index];
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSel ? ClayColors.deepPurple : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isSel ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel('Description / Notes (Optional)'),
          TextFormField(
            controller: _descController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 13.5),
            decoration: _inputDecoration('Enter summary, themes, or personal notes...', Icons.notes_rounded),
          ),
          const SizedBox(height: 28),

          ClayButton(
            label: 'Add to Sanctuary',
            isLoading: _isSavingManual,
            onPressed: _handleManualSave,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: ClayColors.textDark,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: ClayColors.primaryPurple, size: 20),
      filled: true,
      fillColor: Colors.white,
      hintStyle: GoogleFonts.inter(fontSize: 13.5, color: ClayColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE4DEF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE4DEF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ClayColors.deepPurple, width: 2),
      ),
    );
  }
}

class _FormatBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FormatBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EBF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2DCF0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ClayColors.deepPurple),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: ClayColors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }
}

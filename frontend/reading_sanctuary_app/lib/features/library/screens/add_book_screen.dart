import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reading_sanctuary_app/core/widgets/clay_components.dart';
import 'package:reading_sanctuary_app/shared/models/book.dart';
import 'package:reading_sanctuary_app/shared/services/providers.dart';
import 'package:reading_sanctuary_app/features/authentication/presentation/widgets/clay_button.dart';
import 'package:reading_sanctuary_app/features/notifications/application/notifications_provider.dart';

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

  String _selectedGenre = 'Fiction';
  ReadingStatus _status = ReadingStatus.wantToRead;
  bool _hasEbook = true;
  bool _hasAudiobook = false;
  int _selectedColorIndex = 0;
  bool _isSaving = false;

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
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    final pages = int.tryParse(_pagesController.text.trim()) ?? 250;
    final description = _descController.text.trim();

    final formats = <BookFormat>[
      if (_hasEbook) BookFormat.ebook,
      if (_hasAudiobook) BookFormat.audiobook,
    ];
    if (formats.isEmpty) formats.add(BookFormat.ebook);

    final newBook = Book(
      id: 'book-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      author: author,
      genre: _selectedGenre,
      description: description.isNotEmpty ? description : 'A wonderful addition to your reading sanctuary.',
      status: _status,
      progress: _status == ReadingStatus.completed ? 1.0 : (_status == ReadingStatus.currentlyReading ? 0.05 : 0.0),
      pages: pages,
      formats: formats,
      addedAt: DateTime.now(),
      coverColors: _colorPalettes[_selectedColorIndex],
    );

    try {
      await ref.read(booksProvider.notifier).addBook(newBook);
      ref.read(notificationsProvider.notifier).addNotification(
            title: 'Book Added to Library',
            message: '"$title" by $author has been added to your collection.',
            icon: Icons.bookmark_added_rounded,
            color: ClayColors.deepPurple,
          );

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
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save book: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Add New Book',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ClayColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Book Title
                _buildLabel('Book Title *'),
                TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                  decoration: _inputDecoration('Enter book title', Icons.title_rounded),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a book title' : null,
                ),
                const SizedBox(height: 16),

                // Author
                _buildLabel('Author *'),
                TextFormField(
                  controller: _authorController,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                  decoration: _inputDecoration('Enter author name', Icons.person_outline_rounded),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter the author name' : null,
                ),
                const SizedBox(height: 16),

                // Genre selection chips
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

                // Reading Status & Pages row
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

                // Formats Available
                _buildLabel('Formats Available'),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('eBook'),
                      selected: _hasEbook,
                      onSelected: (val) => setState(() => _hasEbook = val),
                      selectedColor: ClayColors.lavenderDark.withValues(alpha: 0.3),
                      avatar: const Icon(Icons.tablet_mac_rounded, size: 16),
                    ),
                    const SizedBox(width: 10),
                    FilterChip(
                      label: const Text('Audiobook'),
                      selected: _hasAudiobook,
                      onSelected: (val) => setState(() => _hasAudiobook = val),
                      selectedColor: ClayColors.lavenderDark.withValues(alpha: 0.3),
                      avatar: const Icon(Icons.headphones_rounded, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cover Palette
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
                          child: isSel
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                              : null,
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
                  decoration: _inputDecoration('Enter summary, themes, or personal notes...', Icons.notes_rounded),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ClayButton(
                  label: 'Add to Sanctuary',
                  isLoading: _isSaving,
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
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

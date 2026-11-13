import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/services/providers.dart';
import '../../data/models/bookshelf_model.dart';
import '../providers/bookshelf_provider.dart';
import '../../utils/bookshelf_layouts.dart';
import '../../utils/bookshelf_themes.dart';
import '../widgets/bookshelf_layout_selector.dart';
import '../widgets/bookshelf_preview.dart';
import '../widgets/bookshelf_theme_picker.dart';

class EditBookshelfScreen extends ConsumerStatefulWidget {
  final BookshelfModel? existingShelf;

  const EditBookshelfScreen({super.key, this.existingShelf});

  @override
  ConsumerState<EditBookshelfScreen> createState() => _EditBookshelfScreenState();
}

class _EditBookshelfScreenState extends ConsumerState<EditBookshelfScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  late String _themeId;
  late String _themeColor;
  late String _accentColor;
  late String _iconKey;
  late BookshelfLayoutStyle _layoutStyle;
  late BookshelfBackgroundStyle _backgroundStyle;
  late bool _isFavorite;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _iconChoices = const [
    {'key': 'shelves', 'icon': Icons.shelves, 'label': 'Shelves'},
    {'key': 'book', 'icon': Icons.auto_stories_rounded, 'label': 'Book'},
    {'key': 'favorite', 'icon': Icons.favorite_rounded, 'label': 'Heart'},
    {'key': 'star', 'icon': Icons.star_rounded, 'label': 'Star'},
    {'key': 'bookmark', 'icon': Icons.bookmark_rounded, 'label': 'Ribbon'},
    {'key': 'fire', 'icon': Icons.local_fire_department_rounded, 'label': 'Fire'},
    {'key': 'magic', 'icon': Icons.auto_awesome_rounded, 'label': 'Magic'},
  ];

  @override
  void initState() {
    super.initState();
    final shelf = widget.existingShelf;
    _nameController = TextEditingController(text: shelf?.name ?? '');
    _descController = TextEditingController(text: shelf?.description ?? '');

    _themeColor = shelf?.themeColor ?? '#2C221E';
    _accentColor = shelf?.accentColor ?? '#D4AF37';

    // Find closest theme matching hex or default to dark_academia
    final matchedTheme = BookshelfThemes.all.firstWhere(
      (t) => BookshelfThemes.toHex(t.primaryColor).toUpperCase() == _themeColor.toUpperCase(),
      orElse: () => BookshelfThemes.darkAcademia,
    );
    _themeId = matchedTheme.id;

    _iconKey = shelf?.icon ?? 'shelves';
    _layoutStyle = BookshelfLayoutStyle.fromKey(shelf?.layoutStyle);
    _backgroundStyle = BookshelfBackgroundStyle.fromKey(shelf?.backgroundStyle);
    _isFavorite = shelf?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  IconData _resolveCurrentIcon() {
    for (final c in _iconChoices) {
      if (c['key'] == _iconKey) return c['icon'] as IconData;
    }
    return Icons.shelves;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingShelf != null;
    final allBooks = ref.watch(booksProvider).valueOrNull ?? [];
    final previewTheme = BookshelfThemes.findById(_themeId);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F0FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F0FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: ClayColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Customize Bookshelf' : 'Create Bookshelf',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ClayColors.textDark,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isFavorite ? 'Remove from favorites' : 'Mark as favorite',
            icon: Icon(
              _isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
              color: ClayColors.amberDark,
              size: 24,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            // Live Preview Card
            BookshelfPreview(
              name: _nameController.text,
              description: _descController.text,
              icon: _resolveCurrentIcon(),
              theme: previewTheme,
              layoutStyle: _layoutStyle,
              backgroundStyle: _backgroundStyle,
              sampleBooks: allBooks.take(4).toList(),
            ),

            const SizedBox(height: 24),

            // Shelf Name
            Text(
              'Shelf Name',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ClayColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a shelf name';
                return null;
              },
              style: GoogleFonts.inter(fontSize: 14, color: ClayColors.textDark),
              decoration: InputDecoration(
                hintText: 'e.g., Dark Romance, 2026 Reads, Comfort Corner',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: ClayColors.clayBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: ClayColors.clayBorder),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: ClayColors.primaryPurple, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Description
            Text(
              'Description (Optional)',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ClayColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descController,
              onChanged: (_) => setState(() {}),
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 13.5, color: ClayColors.textDark),
              decoration: InputDecoration(
                hintText: 'A short note about the books on this shelf...',
                hintStyle: GoogleFonts.inter(fontSize: 13, color: ClayColors.textMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: ClayColors.clayBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: ClayColors.clayBorder),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: ClayColors.primaryPurple, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Icon Choice
            Text(
              'Shelf Icon',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: ClayColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _iconChoices.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final choice = _iconChoices[i];
                  final isSelected = choice['key'] == _iconKey;
                  return InkWell(
                    onTap: () => setState(() => _iconKey = choice['key'] as String),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? ClayColors.primaryPurple : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? ClayColors.softLilac : ClayColors.clayBorder,
                          width: isSelected ? 1.8 : 1,
                        ),
                      ),
                      child: Icon(
                        choice['icon'] as IconData,
                        color: isSelected ? Colors.white : ClayColors.textMuted,
                        size: 22,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Aesthetic Theme Picker
            BookshelfThemePicker(
              selectedThemeId: _themeId,
              onThemeSelected: (theme) {
                setState(() {
                  _themeId = theme.id;
                  _themeColor = BookshelfThemes.toHex(theme.primaryColor);
                  _accentColor = BookshelfThemes.toHex(theme.accentColor);
                });
              },
            ),

            const SizedBox(height: 24),

            // Layout & Background Style
            BookshelfLayoutSelector(
              selectedLayout: _layoutStyle,
              onLayoutChanged: (layout) => setState(() => _layoutStyle = layout),
              selectedBackground: _backgroundStyle,
              onBackgroundChanged: (bg) => setState(() => _backgroundStyle = bg),
            ),

            const SizedBox(height: 32),

            // Save / Submit Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveShelf,
              style: ElevatedButton.styleFrom(
                backgroundColor: ClayColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: ClayColors.softLilac, width: 1.2),
                ),
                elevation: 3,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isEditing ? 'Save Customization' : 'Create Bookshelf',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _saveShelf() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(bookshelfListNotifierProvider.notifier);
      final name = _nameController.text.trim();
      final description = _descController.text.trim();

      if (widget.existingShelf != null) {
        await notifier.updateShelf(
          shelfId: widget.existingShelf!.id,
          name: name,
          description: description,
          themeColor: _themeColor,
          accentColor: _accentColor,
          icon: _iconKey,
          backgroundStyle: _backgroundStyle.key,
          layoutStyle: _layoutStyle.key,
          isFavorite: _isFavorite,
        );
      } else {
        await notifier.createShelf(
          name: name,
          description: description,
          themeColor: _themeColor,
          accentColor: _accentColor,
          icon: _iconKey,
          backgroundStyle: _backgroundStyle.key,
          layoutStyle: _layoutStyle.key,
          isFavorite: _isFavorite,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingShelf != null
                  ? 'Updated "$name" shelf!'
                  : 'Created "$name" bookshelf!',
            ),
            backgroundColor: const Color(0xFF2E9E67),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bookshelf: $e'),
            backgroundColor: const Color(0xFFC94A4A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

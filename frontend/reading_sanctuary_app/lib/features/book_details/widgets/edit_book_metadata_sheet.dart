import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';

class EditBookMetadataSheet extends ConsumerStatefulWidget {
  final Book book;

  const EditBookMetadataSheet({super.key, required this.book});

  @override
  ConsumerState<EditBookMetadataSheet> createState() => _EditBookMetadataSheetState();
}

class _EditBookMetadataSheetState extends ConsumerState<EditBookMetadataSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _genreController;
  late TextEditingController _descriptionController;
  late TextEditingController _publisherController;
  late TextEditingController _isbnController;
  late TextEditingController _totalPagesController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _customTropeController;

  late double _rating;
  late int _ratingOutOf100;
  late int _spiceRating;
  String? _recommendation;
  String? _mood;
  String? _acquisitionMethod;
  String _currency = '₹';
  DateTime? _purchaseDate;
  DateTime? _startDate;
  DateTime? _completionDate;
  late List<String> _tropes;
  bool _isSaving = false;

  static const List<String> _recommendationOptions = [
    'Highly Recommended',
    'Recommended',
    'Maybe',
    'Not Recommended',
  ];

  static const List<String> _acquisitionOptions = [
    'Purchased',
    'Gifted',
    'Borrowed',
    'Library',
    'Free download',
    'Subscription',
    'Other',
  ];

  static const List<String> _currencyOptions = ['₹', '\$', '€', '£', '¥'];

  static const List<String> _moodOptions = [
    'Dark',
    'Cozy',
    'Emotional',
    'Suspenseful',
    'Romantic',
    'Lighthearted',
    'Mysterious',
    'Melancholic',
    'Philosophical',
  ];

  static const List<String> _presetTropes = [
    'Enemies to Lovers',
    'Friends to Lovers',
    'Second Chance',
    'Forced Proximity',
    'Found Family',
    'Slow Burn',
    'Fake Dating',
    'Dark Romance',
    'Chosen One',
    'Morally Grey',
    'Grumpy x Sunshine',
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _titleController = TextEditingController(text: b.title);
    _authorController = TextEditingController(text: b.author);
    _genreController = TextEditingController(text: b.genre);
    _descriptionController = TextEditingController(text: b.description);
    _publisherController = TextEditingController(text: b.publisher ?? '');
    _isbnController = TextEditingController(text: b.isbn ?? '');
    _totalPagesController = TextEditingController(text: b.pages.toString());
    _purchasePriceController = TextEditingController(
      text: b.purchasePrice != null ? b.purchasePrice!.toStringAsFixed(2) : '',
    );
    _customTropeController = TextEditingController();

    _rating = b.rating ?? 0.0;
    _ratingOutOf100 = b.ratingOutOf100 ?? (_rating > 0 ? (_rating * 20).round() : 0);
    _spiceRating = b.spiceRating ?? 0;
    _recommendation = b.recommendation;
    _mood = b.mood;
    _acquisitionMethod = b.acquisitionMethod ?? 'Purchased';
    _currency = b.currency ?? '₹';
    _purchaseDate = b.purchaseDate;
    _startDate = b.startDate;
    _completionDate = b.completionDate;
    _tropes = List.from(b.tropes);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _descriptionController.dispose();
    _publisherController.dispose();
    _isbnController.dispose();
    _totalPagesController.dispose();
    _purchasePriceController.dispose();
    _customTropeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(String field) async {
    final now = DateTime.now();
    DateTime initial = now;
    if (field == 'purchase' && _purchaseDate != null) initial = _purchaseDate!;
    if (field == 'start' && _startDate != null) initial = _startDate!;
    if (field == 'completion' && _completionDate != null) initial = _completionDate!;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ClayColors.deepPurple,
              onPrimary: Colors.white,
              onSurface: ClayColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (field == 'purchase') _purchaseDate = picked;
        if (field == 'start') _startDate = picked;
        if (field == 'completion') _completionDate = picked;
      });
    }
  }

  void _addCustomTrope() {
    final text = _customTropeController.text.trim();
    if (text.isNotEmpty && !_tropes.contains(text)) {
      setState(() {
        _tropes.add(text);
        _customTropeController.clear();
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate != null && _completionDate != null && _completionDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completion date cannot be before start date'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final pages = int.tryParse(_totalPagesController.text.trim()) ?? widget.book.pages;
      final price = double.tryParse(_purchasePriceController.text.trim());

      final updated = widget.book.copyWith(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _genreController.text.trim(),
        description: _descriptionController.text.trim(),
        publisher: _publisherController.text.trim().isNotEmpty ? _publisherController.text.trim() : null,
        isbn: _isbnController.text.trim().isNotEmpty ? _isbnController.text.trim() : null,
        pages: pages,
        rating: _rating,
        ratingOutOf100: _ratingOutOf100,
        spiceRating: _spiceRating,
        recommendation: _recommendation,
        mood: _mood,
        acquisitionMethod: _acquisitionMethod,
        purchasePrice: price,
        currency: _currency,
        purchaseDate: _purchaseDate,
        startDate: _startDate,
        completionDate: _completionDate,
        tropes: _tropes,
      );

      await ref.read(booksProvider.notifier).updateBookDetails(updated);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated "${updated.title}" metadata'),
            backgroundColor: ClayColors.deepPurple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save metadata: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ClayColors.softLilac,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Book Details',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: ClayColors.textDark,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ClayColors.deepPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: _isSaving ? null : _saveChanges,
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Save',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ClayColors.clayBorder),

          // Scrollable Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  // --- Basic Info Section ---
                  _buildSectionHeader('Basic Information', Icons.info_outline_rounded),
                  const SizedBox(height: 10),
                  _buildTextField(_titleController, 'Title', 'Book title', validator: (v) => v?.trim().isEmpty == true ? 'Title is required' : null),
                  const SizedBox(height: 10),
                  _buildTextField(_authorController, 'Author', 'Author name', validator: (v) => v?.trim().isEmpty == true ? 'Author is required' : null),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_genreController, 'Genre', 'Main genre')),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _totalPagesController,
                          'Total Pages',
                          '350',
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n != null && n < 0) return 'Invalid pages';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    _descriptionController,
                    'Description',
                    'A brief summary of the book...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // --- Ratings & Recommendations ---
                  _buildSectionHeader('Ratings & Recommendation', Icons.star_rounded),
                  const SizedBox(height: 12),

                  // Star Rating
                  Row(
                    children: [
                      Text(
                        'Star Rating (${_rating.toStringAsFixed(1)})',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                      ),
                      const Spacer(),
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            i <= _rating
                                ? Icons.star_rounded
                                : (i - 0.5 <= _rating ? Icons.star_half_rounded : Icons.star_border_rounded),
                            color: ClayColors.amber,
                            size: 26,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = (i == _rating.toInt() && _rating % 1 == 0) ? (i - 0.5) : i.toDouble();
                              _ratingOutOf100 = (_rating * 20).round();
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Numerical Rating out of 100
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Numerical Rating',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ClayColors.lightLilac,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_ratingOutOf100 / 100',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: ClayColors.deepPurple),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _ratingOutOf100.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    activeColor: ClayColors.deepPurple,
                    inactiveColor: const Color(0xFFE5DCF4),
                    onChanged: (val) {
                      setState(() {
                        _ratingOutOf100 = val.round();
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Spice Rating (0 to 5)
                  Row(
                    children: [
                      Text(
                        'Spice Rating ($_spiceRating / 5)',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                      ),
                      const Spacer(),
                      for (var i = 1; i <= 5; i++)
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            i <= _spiceRating ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
                            color: i <= _spiceRating ? ClayColors.coral : ClayColors.softLilac,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _spiceRating = _spiceRating == i ? 0 : i;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Recommendation
                  Text(
                    'Recommendation',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _recommendationOptions.map((opt) {
                      final isSelected = _recommendation == opt;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(opt),
                        selectedColor: ClayColors.deepPurple,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : ClayColors.textDark,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: isSelected ? ClayColors.deepPurple : ClayColors.softLilac),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _recommendation = isSelected ? null : opt;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // --- Tropes & Mood ---
                  _buildSectionHeader('Tropes & Mood', Icons.auto_awesome_rounded),
                  const SizedBox(height: 10),

                  // Mood Selection
                  Text(
                    'Mood',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _moodOptions.map((m) {
                      final isSelected = _mood == m;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Text(m),
                        selectedColor: const Color(0xFFC5A059),
                        labelStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : ClayColors.textDark,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: isSelected ? const Color(0xFFC5A059) : ClayColors.softLilac),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _mood = isSelected ? null : m;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Tropes Selection & Custom Addition
                  Text(
                    'Tropes',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: ClayColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._presetTropes.map((t) {
                        final isSelected = _tropes.contains(t);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(t),
                          selectedColor: ClayColors.lavender,
                          labelStyle: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? ClayColors.deepPurple : ClayColors.textDark,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: isSelected ? ClayColors.primaryPurple : ClayColors.softLilac),
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _tropes.add(t);
                              } else {
                                _tropes.remove(t);
                              }
                            });
                          },
                        );
                      }),
                      // Selected custom tropes
                      ..._tropes.where((t) => !_presetTropes.contains(t)).map((t) {
                        return Chip(
                          label: Text(t),
                          backgroundColor: ClayColors.lavender,
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            setState(() => _tropes.remove(t));
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: ClayColors.primaryPurple),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _customTropeController,
                          'Add Custom Trope',
                          'e.g. He falls first',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addCustomTrope,
                        icon: const Icon(Icons.add_circle, color: ClayColors.deepPurple, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Acquisition & Purchase Details ---
                  _buildSectionHeader('Acquisition & Pricing', Icons.shopping_bag_outlined),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _acquisitionMethod,
                    decoration: _inputDecoration('Acquisition Method'),
                    dropdownColor: Colors.white,
                    items: _acquisitionOptions.map((opt) {
                      return DropdownMenuItem(value: opt, child: Text(opt, style: GoogleFonts.inter(fontSize: 13)));
                    }).toList(),
                    onChanged: (v) => setState(() => _acquisitionMethod = v),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration: _inputDecoration('Currency'),
                          dropdownColor: Colors.white,
                          items: _currencyOptions.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)));
                          }).toList(),
                          onChanged: (v) => setState(() => _currency = v ?? '₹'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _purchasePriceController,
                          'Purchase Price',
                          '499.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildDatePickerTile(
                    label: 'Purchase Date',
                    date: _purchaseDate,
                    dateFormat: dateFormat,
                    onTap: () => _pickDate('purchase'),
                    onClear: () => setState(() => _purchaseDate = null),
                  ),
                  const SizedBox(height: 20),

                  // --- Publication & Identifiers ---
                  _buildSectionHeader('Edition & Identifiers', Icons.menu_book_rounded),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_publisherController, 'Publisher', 'Penguin, Tor, etc.')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_isbnController, 'ISBN', '978-0...')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- Reading Dates ---
                  _buildSectionHeader('Reading Timeline', Icons.calendar_month_rounded),
                  const SizedBox(height: 10),
                  _buildDatePickerTile(
                    label: 'Reading Start Date',
                    date: _startDate,
                    dateFormat: dateFormat,
                    onTap: () => _pickDate('start'),
                    onClear: () => setState(() => _startDate = null),
                  ),
                  const SizedBox(height: 10),
                  _buildDatePickerTile(
                    label: 'Reading Completion Date',
                    date: _completionDate,
                    dateFormat: dateFormat,
                    onTap: () => _pickDate('completion'),
                    onClear: () => setState(() => _completionDate = null),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: ClayColors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: ClayColors.deepPurple,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 13, color: ClayColors.textDark),
      decoration: _inputDecoration(label, hint: hint),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted),
      hintStyle: GoogleFonts.inter(fontSize: 12, color: ClayColors.textMuted.withValues(alpha: 0.6)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ClayColors.softLilac),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ClayColors.softLilac),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: ClayColors.deepPurple, width: 1.5),
      ),
    );
  }

  Widget _buildDatePickerTile({
    required String label,
    required DateTime? date,
    required DateFormat dateFormat,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClayColors.softLilac),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: ClayColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                date != null ? dateFormat.format(date) : 'Not set',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: date != null ? ClayColors.textDark : ClayColors.textMuted,
                ),
              ),
            ],
          ),
          Row(
            children: [
              if (date != null)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: ClayColors.textMuted),
                  onPressed: onClear,
                ),
              IconButton(
                icon: const Icon(Icons.calendar_today_rounded, size: 18, color: ClayColors.deepPurple),
                onPressed: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

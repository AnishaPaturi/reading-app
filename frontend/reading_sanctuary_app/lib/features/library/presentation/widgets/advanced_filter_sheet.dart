import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';

class LibraryFilterState {
  final ReadingStatus? readingStatus;
  final String? bookStatus; // 'available', 'archived', 'deleted'
  final String? author;
  final String? genre;
  final String? format; // 'PDF', 'EPUB', 'MP3', 'M4B', 'M4A'
  final double? minRating;

  const LibraryFilterState({
    this.readingStatus,
    this.bookStatus,
    this.author,
    this.genre,
    this.format,
    this.minRating,
  });

  bool get hasActiveFilters =>
      readingStatus != null ||
      bookStatus != null ||
      author != null ||
      genre != null ||
      format != null ||
      minRating != null;

  LibraryFilterState copyWith({
    ReadingStatus? readingStatus,
    bool clearReadingStatus = false,
    String? bookStatus,
    bool clearBookStatus = false,
    String? author,
    bool clearAuthor = false,
    String? genre,
    bool clearGenre = false,
    String? format,
    bool clearFormat = false,
    double? minRating,
    bool clearMinRating = false,
  }) {
    return LibraryFilterState(
      readingStatus: clearReadingStatus ? null : (readingStatus ?? this.readingStatus),
      bookStatus: clearBookStatus ? null : (bookStatus ?? this.bookStatus),
      author: clearAuthor ? null : (author ?? this.author),
      genre: clearGenre ? null : (genre ?? this.genre),
      format: clearFormat ? null : (format ?? this.format),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }
}

class AdvancedFilterSheet extends StatefulWidget {
  final LibraryFilterState initialFilter;
  final List<String> availableAuthors;
  final List<String> availableGenres;
  final ValueChanged<LibraryFilterState> onApply;

  const AdvancedFilterSheet({
    super.key,
    required this.initialFilter,
    required this.availableAuthors,
    required this.availableGenres,
    required this.onApply,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late LibraryFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final formats = ['EPUB', 'PDF', 'MP3', 'M4B', 'M4A'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD3C5EE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Books',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _state = const LibraryFilterState();
                  });
                },
                child: Text(
                  'Reset All',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: ClayColors.coral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Options in Scrollable List
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Reading Status Filter
                  _buildSectionHeader('Reading Status'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in [
                        ReadingStatus.currentlyReading,
                        ReadingStatus.wantToRead,
                        ReadingStatus.completed,
                        ReadingStatus.onHold,
                        ReadingStatus.dnf,
                      ])
                        ChoiceChip(
                          label: Text(s.label),
                          selected: _state.readingStatus == s,
                          onSelected: (val) {
                            setState(() {
                              _state = _state.copyWith(
                                readingStatus: val ? s : null,
                                clearReadingStatus: !val,
                              );
                            });
                          },
                          selectedColor: ClayColors.deepPurple,
                          labelStyle: TextStyle(
                            color: _state.readingStatus == s ? Colors.white : ClayColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Book Status Filter
                  _buildSectionHeader('Book Status'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in [
                        ('available', 'Available'),
                        ('archived', 'Archived'),
                        ('deleted', 'Deleted / Trash'),
                      ])
                        ChoiceChip(
                          label: Text(item.$2),
                          selected: _state.bookStatus == item.$1,
                          onSelected: (val) {
                            setState(() {
                              _state = _state.copyWith(
                                bookStatus: val ? item.$1 : null,
                                clearBookStatus: !val,
                              );
                            });
                          },
                          selectedColor: ClayColors.deepPurple,
                          labelStyle: TextStyle(
                            color: _state.bookStatus == item.$1 ? Colors.white : ClayColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Format Filter
                  _buildSectionHeader('File Format'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in formats)
                        ChoiceChip(
                          label: Text(f),
                          selected: _state.format == f,
                          onSelected: (val) {
                            setState(() {
                              _state = _state.copyWith(
                                format: val ? f : null,
                                clearFormat: !val,
                              );
                            });
                          },
                          selectedColor: ClayColors.deepPurple,
                          labelStyle: TextStyle(
                            color: _state.format == f ? Colors.white : ClayColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. Rating Filter
                  _buildSectionHeader('Minimum Rating'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in [4.0, 3.0, 2.0, 1.0])
                        ChoiceChip(
                          label: Text('★ ${r.toInt()}+ stars'),
                          selected: _state.minRating == r,
                          onSelected: (val) {
                            setState(() {
                              _state = _state.copyWith(
                                minRating: val ? r : null,
                                clearMinRating: !val,
                              );
                            });
                          },
                          selectedColor: ClayColors.deepPurple,
                          labelStyle: TextStyle(
                            color: _state.minRating == r ? Colors.white : ClayColors.textDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. Genre Filter
                  if (widget.availableGenres.isNotEmpty) ...[
                    _buildSectionHeader('Genre'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final g in widget.availableGenres)
                          ChoiceChip(
                            label: Text(g),
                            selected: _state.genre == g,
                            onSelected: (val) {
                              setState(() {
                                _state = _state.copyWith(
                                  genre: val ? g : null,
                                  clearGenre: !val,
                                );
                              });
                            },
                            selectedColor: ClayColors.deepPurple,
                            labelStyle: TextStyle(
                              color: _state.genre == g ? Colors.white : ClayColors.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 6. Author Filter
                  if (widget.availableAuthors.isNotEmpty) ...[
                    _buildSectionHeader('Author'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in widget.availableAuthors)
                          ChoiceChip(
                            label: Text(a),
                            selected: _state.author == a,
                            onSelected: (val) {
                              setState(() {
                                _state = _state.copyWith(
                                  author: val ? a : null,
                                  clearAuthor: !val,
                                );
                              });
                            },
                            selectedColor: ClayColors.deepPurple,
                            labelStyle: TextStyle(
                              color: _state.author == a ? Colors.white : ClayColors.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),

          // Apply Button
          ElevatedButton(
            onPressed: () {
              widget.onApply(_state);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ClayColors.deepPurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'Apply Filters',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: ClayColors.textDark,
        ),
      ),
    );
  }
}

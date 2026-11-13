import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/book_cover.dart';
import '../../../shared/models/book.dart';
import '../../../shared/services/providers.dart';
import '../models/dnf_completion_data.dart';

class DnfCompletionCard extends ConsumerStatefulWidget {
  final DnfCompletionData data;
  final VoidCallback onBackToShelf;
  final VoidCallback onDnfShelf;
  final VoidCallback onUndo;

  const DnfCompletionCard({
    super.key,
    required this.data,
    required this.onBackToShelf,
    required this.onDnfShelf,
    required this.onUndo,
  });

  @override
  ConsumerState<DnfCompletionCard> createState() => _DnfCompletionCardState();
}

class _DnfCompletionCardState extends ConsumerState<DnfCompletionCard> {
  late String? _selectedReason;
  late final TextEditingController _notesController;
  bool _isSavingNote = false;

  static const List<(String, String)> _predefinedReasons = [
    ('PACING', 'Pacing Dragged'),
    ('NOT_MY_VIBE', 'Not My Vibe'),
    ('LOST_INTEREST', 'Lost Interest'),
    ('WRITING_STYLE', 'Writing Style'),
    ('WRONG_TIME', 'Right Book, Wrong Time'),
    ('DISAPPOINTING', 'Disappointing Plot'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedReason = widget.data.dnfReason;
    _notesController = TextEditingController(text: widget.data.dnfNotes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _updateReason(String reasonKey) {
    setState(() {
      _selectedReason = _selectedReason == reasonKey ? null : reasonKey;
    });
    ref.read(booksProvider.notifier).setStatus(
          widget.data.bookId,
          ReadingStatus.dnf,
          dnfDate: widget.data.dnfDate,
          dnfReason: _selectedReason,
          dnfNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
  }

  Future<void> _saveNote() async {
    setState(() => _isSavingNote = true);
    await ref.read(booksProvider.notifier).setStatus(
          widget.data.bookId,
          ReadingStatus.dnf,
          dnfDate: widget.data.dnfDate,
          dnfReason: _selectedReason,
          dnfNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
    if (mounted) {
      setState(() => _isSavingNote = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reflection saved.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeGold = Color(0xFFD4AF37); // Champagne gold
    const lightGold = Color(0xFFF3E5AB);
    const mutedGold = Color(0xFFC5A059);
    const darkCardBg = Color(0xFF141216);
    final dnfFormattedDate = DateFormat.yMMMd().format(widget.data.dnfDate);
    final pctStopped = (widget.data.readingProgress * 100).round();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Subtle ornate flame/crest icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF201815),
              border: Border.all(color: mutedGold.withValues(alpha: 0.4), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFFF9800),
              size: 24,
            ),
          ),
          const SizedBox(height: 16),

          // Main Title
          Text(
            'DID NOT FINISH',
            textAlign: TextAlign.center,
            style: GoogleFonts.cinzel(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 4.0,
              color: lightGold,
            ),
          ),
          const SizedBox(height: 6),

          // Poetic Tagline
          Text(
            "SOME STORIES AREN'T MEANT TO BE FINISHED.",
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.2,
              fontStyle: FontStyle.italic,
              color: mutedGold,
            ),
          ),
          const SizedBox(height: 28),

          // Dynamic Book Cover with Ember-Kissed Shadow
          Container(
            width: 140,
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: mutedGold.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6F00).withValues(alpha: 0.15),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.8),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: BookCover(
                book: widget.data.book,
                elevation: 0,
                borderRadius: 9,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title & Author
          Text(
            widget.data.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.data.author,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFFA098A8),
            ),
          ),
          const SizedBox(height: 28),

          // Progress and Date Stats Dual Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: darkCardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Stopped at
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$pctStopped%',
                        style: GoogleFonts.cinzel(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFFFAB40),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PROGRESS STOPPED',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: const Color(0xFF8E8698),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.data.currentPage} of ${widget.data.totalPages} pages',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B6275),
                        ),
                      ),
                    ],
                  ),
                ),

                // Elegant divider
                Container(
                  width: 1,
                  height: 48,
                  color: Colors.white.withValues(alpha: 0.12),
                ),

                // DNF Date
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        dnfFormattedDate,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: lightGold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'RETIREMENT DATE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: const Color(0xFF8E8698),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Saved to Sanctuary',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B6275),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Optional Reasons Selector
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Why are you parting ways?',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: mutedGold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reason in _predefinedReasons)
                ChoiceChip(
                  label: Text(
                    reason.$2,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedReason == reason.$1
                          ? const Color(0xFF140D05)
                          : const Color(0xFFC7B8D6),
                    ),
                  ),
                  selected: _selectedReason == reason.$1,
                  selectedColor: const Color(0xFFFFB74D),
                  backgroundColor: const Color(0xFF231C28),
                  side: BorderSide(
                    color: _selectedReason == reason.$1
                        ? const Color(0xFFFFB74D)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                  onSelected: (_) => _updateReason(reason.$1),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // Optional Thoughts Note Field
          TextField(
            controller: _notesController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Leave a parting thought for your future self...',
              hintStyle: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF675C73),
                fontStyle: FontStyle.italic,
              ),
              filled: true,
              fillColor: const Color(0xFF1B1722),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: themeGold.withValues(alpha: 0.5)),
              ),
              suffixIcon: IconButton(
                icon: _isSavingNote
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                      )
                    : const Icon(Icons.check_rounded, color: Color(0xFFD4AF37), size: 18),
                tooltip: 'Save thought',
                onPressed: _saveNote,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Philosophical Epilogue
          Text(
            '“A book abandoned, not forgotten.”',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF8C7F99),
            ),
          ),
          const SizedBox(height: 32),

          // Primary Actions: DNF Shelf & Back to Shelf
          Row(
            children: [
              // Back to Shelf Button
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onBackToShelf,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: lightGold,
                    side: BorderSide(color: mutedGold.withValues(alpha: 0.6), width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Back to Shelf',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // DNF Shelf Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onDnfShelf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC5A059),
                    foregroundColor: const Color(0xFF140D05),
                    elevation: 6,
                    shadowColor: const Color(0xFFFFB300).withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.auto_stories_rounded, size: 18),
                  label: Text(
                    'DNF Shelf',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Undo Action
          TextButton.icon(
            onPressed: widget.onUndo,
            icon: const Icon(Icons.undo_rounded, size: 15, color: Color(0xFF9E8FAA)),
            label: Text(
              'Accidentally retired? Undo DNF',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9E8FAA),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFF9E8FAA).withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

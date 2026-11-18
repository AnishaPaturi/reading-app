import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/widgets/clay_components.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/services/providers.dart';

class ScanSpinesSheet extends StatefulWidget {
  const ScanSpinesSheet({super.key});

  @override
  State<ScanSpinesSheet> createState() => _ScanSpinesSheetState();
}

class _ScanSpinesSheetState extends State<ScanSpinesSheet> {
  bool _isScanning = false;
  bool _hasScanned = false;
  final List<Map<String, dynamic>> _detectedSpines = [];
  final Set<int> _selectedIndices = {};

  Future<void> _simulateSpineScan() async {
    setState(() {
      _isScanning = true;
    });

    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    setState(() {
      _isScanning = false;
      _hasScanned = true;
      _detectedSpines.clear();
      _detectedSpines.addAll([
        {
          'title': 'The Secret History',
          'author': 'Donna Tartt',
          'genre': 'Dark Academia',
          'confidence': '96%',
          'isMatch': true,
        },
        {
          'title': 'Babel',
          'author': 'R.F. Kuang',
          'genre': 'Historical Fantasy',
          'confidence': '92%',
          'isMatch': true,
        },
        {
          'title': 'If We Were Villains',
          'author': 'M.L. Rio',
          'genre': 'Mystery',
          'confidence': '88%',
          'isMatch': true,
        },
        {
          'title': 'The Picture of Dorian Gray',
          'author': 'Oscar Wilde',
          'genre': 'Classic',
          'confidence': '85%',
          'isMatch': true,
        },
      ]);
      _selectedIndices.addAll(List.generate(_detectedSpines.length, (i) => i));
    });
  }

  void _addDetectedBooks(WidgetRef ref) {
    final notifier = ref.read(booksProvider.notifier);
    for (final idx in _selectedIndices) {
      final item = _detectedSpines[idx];
      final newBook = Book(
        id: 'scanned_${DateTime.now().millisecondsSinceEpoch}_$idx',
        title: item['title'].toString(),
        author: item['author'].toString(),
        genre: item['genre'].toString(),
        description: 'Imported via Spine Camera Scanner',
        status: ReadingStatus.wantToRead,
        progress: 0.0,
        pages: 350,
        formats: const [BookFormat.ebook],
        files: const [],
        addedAt: DateTime.now(),
        coverColors: const [Color(0xFF4C3D6E), Color(0xFF2E2448)],
      );
      notifier.addBook(newBook);
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_selectedIndices.length} books to your bookshelf!'),
        backgroundColor: ClayColors.deepPurple,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
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

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.center_focus_strong_rounded, color: ClayColors.deepPurple, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        'Scan Physical Spines',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: ClayColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: ClayColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Capture an image of your physical bookshelf. OCR detects the spine titles so you can quickly catalog them.',
                style: GoogleFonts.inter(fontSize: 12.5, color: ClayColors.textMuted, height: 1.3),
              ),
              const SizedBox(height: 16),

              // Scanner Viewfinder Area
              if (!_hasScanned) ...[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E172A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ClayColors.deepPurple.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isScanning) ...[
                          const CircularProgressIndicator(color: Color(0xFFFFB300)),
                          Positioned(
                            bottom: 24,
                            child: Text(
                              'Analyzing book spines with OCR...',
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ] else ...[
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt_outlined, size: 48, color: Color(0xFFC7B8E8)),
                              const SizedBox(height: 12),
                              Text(
                                'Align book spines horizontally or vertically',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _simulateSpineScan,
                  icon: const Icon(Icons.camera_rounded, color: Colors.white, size: 20),
                  label: const Text('Capture & Detect Spines', style: TextStyle(color: Colors.white, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClayColors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ] else ...[
                // Review & Confirmation Screen
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detected Spines (${_detectedSpines.length})',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: ClayColors.textDark),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _hasScanned = false;
                        });
                      },
                      child: const Text('Scan Again'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView.separated(
                    itemCount: _detectedSpines.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _detectedSpines[index];
                      final isSelected = _selectedIndices.contains(index);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIndices.add(index);
                            } else {
                              _selectedIndices.remove(index);
                            }
                          });
                        },
                        activeColor: ClayColors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: isSelected ? ClayColors.deepPurple : const Color(0xFFEADBFC)),
                        ),
                        tileColor: Colors.white,
                        title: Text(
                          item['title'].toString(),
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: ClayColors.textDark),
                        ),
                        subtitle: Text(
                          '${item['author']} · ${item['genre']} (${item['confidence']} confidence)',
                          style: GoogleFonts.inter(fontSize: 11.5, color: ClayColors.textMuted),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _selectedIndices.isEmpty ? null : () => _addDetectedBooks(ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ClayColors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'Add ${_selectedIndices.length} Books to Bookshelf',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

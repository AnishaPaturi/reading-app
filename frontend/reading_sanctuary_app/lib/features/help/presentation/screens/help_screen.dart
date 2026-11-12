import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchController = TextEditingController();
  String _filterQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How does offline reading work?',
      'answer': 'When you download a book or audiobook, its content is cached locally on your device in secure app storage. You can read or listen completely offline with automatic progress synchronization once you reconnect.',
    },
    {
      'question': 'How do I customize my character avatar?',
      'answer': 'Go to your Profile tab and locate the character switcher badge. You can toggle your avatar character, and your theme and mascot will personalize across the entire application.',
    },
    {
      'question': 'How do I edit my display name?',
      'answer': 'Open your Profile tab, switch to Shelves & Settings, and tap "Edit Profile". You can enter your preferred display name which syncs permanently with the database.',
    },
    {
      'question': 'Can I change my gender after setting it?',
      'answer': 'To keep your reading experience and personalized profile consistent, gender is locked once set during registration or initial selection.',
    },
    {
      'question': 'How does Text-to-Speech (TTS) work?',
      'answer': 'For books with EPUB or text formats, the TTS engine segments chapters into natural paragraphs and reads aloud with variable playback speed and sleep timers.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((f) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return f['question']!.toLowerCase().contains(q) || f['answer']!.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: ClayColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Help & Support',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: ClayColors.textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search FAQ bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _filterQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search help topics & FAQs...',
                    prefixIcon: const Icon(Icons.search_rounded, color: ClayColors.primaryPurple),
                    suffixIcon: _filterQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filterQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Quick Contact Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ClayColors.peach,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: ClayColors.peachDark.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.support_agent_rounded, color: Color(0xFFF07067), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need human assistance?',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF3B2017),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Our Sanctuary support team is available 24/7.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF5E392E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Frequently Asked Questions',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: ClayColors.textDark,
                ),
              ),
              const SizedBox(height: 12),

              for (final faq in filteredFaqs) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    iconColor: ClayColors.primaryPurple,
                    collapsedIconColor: ClayColors.textMuted,
                    title: Text(
                      faq['question']!,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ClayColors.textDark,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['answer']!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF5D5270),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

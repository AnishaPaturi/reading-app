import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/clay_components.dart';
import 'highlight_color_picker.dart';

enum AnnotationMenuAction {
  highlight,
  underline,
  note,
  quote,
  copy,
  more,
}

/// Unified floating clay annotation toolbar used across PDF, EPUB, mobile, and web.
class AnnotationContextMenu extends StatefulWidget {
  final String selectedText;
  final int? pageNumber;
  final ValueChanged<HighlightColorOption> onHighlight;
  final ValueChanged<HighlightColorOption>? onUnderline;
  final VoidCallback onAddNote;
  final VoidCallback? onSaveQuote;
  final VoidCallback? onCopy;
  final VoidCallback? onMore;
  final VoidCallback? onDismiss;

  const AnnotationContextMenu({
    super.key,
    required this.selectedText,
    this.pageNumber,
    required this.onHighlight,
    this.onUnderline,
    required this.onAddNote,
    this.onSaveQuote,
    this.onCopy,
    this.onMore,
    this.onDismiss,
  });

  /// Displays the floating annotation toolbar in a non-bottom-sheet floating overlay dialog.
  static Future<void> show(
    BuildContext context, {
    required String selectedText,
    int? pageNumber,
    Rect? targetRect,
    required ValueChanged<HighlightColorOption> onHighlight,
    ValueChanged<HighlightColorOption>? onUnderline,
    required VoidCallback onAddNote,
    VoidCallback? onSaveQuote,
    VoidCallback? onMore,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Toolbar',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final mediaQuery = MediaQuery.of(dialogContext);
        final screenSize = mediaQuery.size;
        final padding = mediaQuery.padding;

        const double toolbarWidth = 350.0;
        const double toolbarHeight = 175.0;

        double top;
        double left;

        if (targetRect != null && targetRect != Rect.zero) {
          left = (targetRect.center.dx - (toolbarWidth / 2))
              .clamp(16.0, screenSize.width - toolbarWidth - 16.0);

          final spaceAbove = targetRect.top - padding.top;
          if (spaceAbove >= toolbarHeight + 16.0) {
            top = targetRect.top - toolbarHeight - 12.0;
          } else {
            top = targetRect.bottom + 12.0;
            if (top + toolbarHeight > screenSize.height - padding.bottom - 16.0) {
              top = (screenSize.height - toolbarHeight) / 2;
            }
          }
        } else {
          left = (screenSize.width - toolbarWidth) / 2;
          top = padding.top + 70.0;
        }

        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: toolbarWidth,
              child: Material(
                color: Colors.transparent,
                child: AnnotationContextMenu(
                  selectedText: selectedText,
                  pageNumber: pageNumber,
                  onHighlight: (color) {
                    Navigator.of(dialogContext).pop();
                    onHighlight(color);
                  },
                  onUnderline: (color) {
                    Navigator.of(dialogContext).pop();
                    if (onUnderline != null) {
                      onUnderline(color);
                    } else {
                      onHighlight(color);
                    }
                  },
                  onAddNote: () {
                    Navigator.of(dialogContext).pop();
                    onAddNote();
                  },
                  onSaveQuote: onSaveQuote != null
                      ? () {
                          Navigator.of(dialogContext).pop();
                          onSaveQuote();
                        }
                      : null,
                  onCopy: () {
                    Clipboard.setData(ClipboardData(text: selectedText));
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Passage copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  onMore: onMore,
                  onDismiss: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  State<AnnotationContextMenu> createState() => _AnnotationContextMenuState();
}

class _AnnotationContextMenuState extends State<AnnotationContextMenu> {
  bool _showPalette = false;
  HighlightStyle _selectedStyle = HighlightStyle.solid;
  HighlightColorOption? _selectedColor;

  void _handleCopy() {
    if (widget.onCopy != null) {
      widget.onCopy!();
    } else {
      Clipboard.setData(ClipboardData(text: widget.selectedText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passage copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
      widget.onDismiss?.call();
    }
  }

  void _handleUnderline() {
    final color = _selectedColor ?? HighlightColors.defaultColor;
    if (widget.onUnderline != null) {
      widget.onUnderline!(color);
    } else {
      widget.onHighlight(color);
    }
  }

  void _handleMore(BuildContext context) {
    if (widget.onMore != null) {
      widget.onMore!();
      return;
    }

    // Default clay actions for "More"
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: ClayColors.cardBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_rounded, color: ClayColors.deepPurple),
              title: Text('Share Passage', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                Clipboard.setData(ClipboardData(text: widget.selectedText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied ready to share!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search_rounded, color: ClayColors.deepPurple),
              title: Text('Web Search', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search initiated')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8FE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClayColors.clayBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33382761),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Passage Preview
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.pageNumber != null)
                        Text(
                          'PAGE ${widget.pageNumber}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: ClayColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      Text(
                        '“${widget.selectedText.trim()}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.lora(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: ClayColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: ClayColors.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    onPressed: widget.onDismiss,
                  ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFEDE5F8)),

          // Body: Either Compact Palette or Main Toolbar Actions
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _showPalette ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: _buildMainToolbar(),
            secondChild: _buildPaletteView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Highlight
          _buildToolItem(
            icon: Icons.brush_rounded,
            label: 'Highlight',
            color: ClayColors.primaryPurple,
            onTap: () {
              setState(() {
                _showPalette = true;
              });
            },
          ),
          // 2. Underline
          _buildToolItem(
            icon: Icons.format_underlined_rounded,
            label: 'Underline',
            color: ClayColors.deepPurple,
            onTap: _handleUnderline,
          ),
          // 3. Note / Add Note
          _buildToolItem(
            icon: Icons.edit_note_rounded,
            label: 'Add Note',
            color: ClayColors.primaryPurple,
            onTap: widget.onAddNote,
          ),
          // 4. Quote
          if (widget.onSaveQuote != null)
            _buildToolItem(
              icon: Icons.format_quote_rounded,
              label: 'Quote',
              color: ClayColors.coral,
              onTap: widget.onSaveQuote!,
            ),
          // 5. Copy
          _buildToolItem(
            icon: Icons.content_copy_rounded,
            label: 'Copy',
            color: ClayColors.textDark,
            onTap: _handleCopy,
          ),
          // 6. More
          _buildToolItem(
            icon: Icons.more_horiz_rounded,
            label: 'More',
            color: ClayColors.textMuted,
            onTap: () => _handleMore(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showPalette = false;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: ClayColors.deepPurple),
                label: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: ClayColors.deepPurple,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              Text(
                'Select Highlight Colour',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: ClayColors.textDark,
                ),
              ),
              const SizedBox(width: 48), // spacer balance
            ],
          ),
          const SizedBox(height: 8),
          HighlightColorPicker(
            selectedHex: _selectedColor?.hex,
            selectedStyle: _selectedStyle,
            showStyles: true,
            onColorSelected: (option) {
              setState(() {
                _selectedColor = option;
              });
              widget.onHighlight(option);
            },
            onStyleSelected: (style) {
              setState(() {
                _selectedStyle = style;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: Color(0xFFEDE5F8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x12382761),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ClayColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/audiobook_duration_utils.dart';

/// Pixel-perfect 3D Claymorphic Audio Player View matching the reference design.
class ClayAudioPlayerView extends StatelessWidget {
  final String title;
  final String? author;
  final String? coverPath;
  final String chapterTitle;
  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final bool isLoading;
  final double playbackSpeed;
  final bool silenceSkipping;
  final bool isSleepTimerActive;
  final Duration? sleepTimerRemaining;
  final VoidCallback onBack;
  final VoidCallback onOptions;
  final VoidCallback onPlayPause;
  final VoidCallback onRewind15;
  final VoidCallback onForward30;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onChapters;
  final VoidCallback onSleepTimer;
  final VoidCallback onBookmark;
  final VoidCallback onSpeed;
  final VoidCallback onToggleSilence;

  const ClayAudioPlayerView({
    super.key,
    required this.title,
    this.author,
    this.coverPath,
    required this.chapterTitle,
    required this.position,
    required this.duration,
    required this.isPlaying,
    this.isLoading = false,
    required this.playbackSpeed,
    required this.silenceSkipping,
    this.isSleepTimerActive = false,
    this.sleepTimerRemaining,
    required this.onBack,
    required this.onOptions,
    required this.onPlayPause,
    required this.onRewind15,
    required this.onForward30,
    required this.onSeek,
    required this.onChapters,
    required this.onSleepTimer,
    required this.onBookmark,
    required this.onSpeed,
    required this.onToggleSilence,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isCompact = screenHeight < 720;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFDDD7F7), // Soft pastel lavender clay background
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Floating Decorative 3D Clay Stars / Sparkles
            Positioned(
              top: isCompact ? 70 : 85,
              right: 18,
              child: const ClaySparkle(
                size: 26,
                color: Color(0xFFA292E4), // Lavender star
                rotation: 0.1,
              ),
            ),
            Positioned(
              top: isCompact ? 100 : 120,
              right: 36,
              child: const ClaySparkle(
                size: 16,
                color: Color(0xFFF39F82), // Small peach star
                rotation: -0.2,
              ),
            ),
            Positioned(
              top: isCompact ? 280 : 330,
              left: 14,
              child: const ClaySparkle(
                size: 15,
                color: Color(0xFF6B58A6), // Deep purple star
                rotation: 0.15,
              ),
            ),
            Positioned(
              top: isCompact ? 305 : 360,
              left: 20,
              child: const ClaySparkle(
                size: 20,
                color: Color(0xFFF5B59E), // Peach star
                rotation: -0.1,
              ),
            ),
            Positioned(
              top: isCompact ? 335 : 395,
              left: 36,
              child: const ClaySparkle(
                size: 10,
                color: Color(0xFF4C3B7E), // Tiny purple dot/star
              ),
            ),
            Positioned(
              bottom: isCompact ? 80 : 100,
              right: 22,
              child: const ClaySparkle(
                size: 14,
                color: Color(0xFFEDE8FF), // Tiny pastel sparkle
                rotation: 0.3,
              ),
            ),

            // Main Content Column
            Column(
              children: [
                // 1. Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      ClayCircularButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onTap: onBack,
                      ),

                      // Title: NOW PLAYING
                      Text(
                        'NOW PLAYING',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: const Color(0xFF22174B),
                        ),
                      ),

                      // Options Button
                      ClayCircularButton(
                        icon: Icons.more_horiz_rounded,
                        tooltip: 'Options',
                        onTap: onOptions,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 2. Central Cream Clay Card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDF5), // Ivory cream
                        borderRadius: BorderRadius.circular(38),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33584594),
                            offset: Offset(0, 16),
                            blurRadius: 30,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.white,
                            offset: Offset(-5, -5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        isCompact ? 16 : 24,
                        20,
                        isCompact ? 16 : 22,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 3D Book Cover
                          Expanded(
                            child: Center(
                              child: Clay3DBookCover(
                                coverPath: coverPath,
                                title: title,
                                author: author,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Chapter Title
                          Text(
                            chapterTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: isCompact ? 18 : 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF22174B),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Recessed Progress Bar + Timestamps
                          ClayRecessedProgressBar(
                            position: position,
                            duration: duration,
                            onSeek: onSeek,
                          ),

                          const SizedBox(height: 14),

                          // Playback Transport Controls: -15s | PLAY/PAUSE | +30s
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ClayTransportPill(
                                label: '-15s',
                                onTap: onRewind15,
                              ),
                              const SizedBox(width: 16),
                              ClayPlayPauseButton(
                                isPlaying: isPlaying,
                                isLoading: isLoading,
                                onTap: onPlayPause,
                              ),
                              const SizedBox(width: 16),
                              ClayTransportPill(
                                label: '+30s',
                                onTap: onForward30,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 3. Secondary Actions Row: Chapters | Sleep Timer | Bookmark
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Chapters Pill
                        ClayActionPill(
                          label: 'Chapters',
                          color: const Color(0xFFF7E6DC), // Soft peach
                          onTap: onChapters,
                        ),
                        const SizedBox(width: 10),

                        // Sleep Timer Pill
                        ClayActionPill(
                          label: isSleepTimerActive && sleepTimerRemaining != null
                              ? '${sleepTimerRemaining!.inMinutes}m'
                              : 'Sleep Timer',
                          icon: Icons.nightlight_round,
                          color: const Color(0xFFDDD7F7), // Soft lavender
                          onTap: onSleepTimer,
                        ),
                        const SizedBox(width: 10),

                        // Bookmark Pill with Coral Ribbon Tab
                        ClayActionPill(
                          label: 'Bookmark',
                          color: const Color(0xFFF7E6DC), // Soft peach
                          hasRibbonBadge: true,
                          onTap: onBookmark,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // 4. Bottom Speed & Silence Skipping Floating Card
                ClaySpeedSilenceCard(
                  speed: playbackSpeed,
                  silenceSkipping: silenceSkipping,
                  onSpeedTap: onSpeed,
                  onSilenceTap: onToggleSilence,
                ),

                const SizedBox(height: 10),

                // Home Indicator Bar
                Center(
                  child: Container(
                    width: 134,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22174B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                SizedBox(height: mediaQuery.padding.bottom > 0 ? mediaQuery.padding.bottom : 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular Clay Button for Top Navigation
class ClayCircularButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const ClayCircularButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        color: Color(0xFFEDE8FB),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x30473582),
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: const Color(0xFF22174B),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3D Physical Hardcover Book Widget matching the reference illustration.
class Clay3DBookCover extends StatelessWidget {
  final String? coverPath;
  final String title;
  final String? author;

  const Clay3DBookCover({
    super.key,
    required this.coverPath,
    required this.title,
    this.author,
  });

  @override
  Widget build(BuildContext context) {
    final hasRealCover = coverPath != null &&
        coverPath!.isNotEmpty &&
        (coverPath!.startsWith('http') || (!kIsWeb && File(coverPath!).existsSync()));

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : 260.0;
        final bookHeight = (maxH * 0.94).clamp(180.0, 270.0);
        final bookWidth = bookHeight * 0.76;

        return Container(
          width: bookWidth,
          height: bookHeight,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x4510163A),
                offset: Offset(0, 14),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Bottom & Right Layered Cream Page Edge
              Positioned(
                left: 10,
                right: 0,
                top: 6,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EEDB), // Cream page edge
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                      bottomLeft: Radius.circular(10),
                    ),
                    border: Border.all(color: const Color(0xFFE2D6BB), width: 1),
                  ),
                ),
              ),

              // Front Hardcover Face
              Positioned(
                left: 0,
                right: 6,
                top: 0,
                bottom: 6,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF222C5C), // Navy blue hardcover
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x25000000),
                        offset: Offset(4, 4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                    child: Stack(
                      children: [
                        // Left Spine Gradient Highlight & Crease
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 20,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFF131A3B),
                                  Color(0xFF323F7E),
                                  Color(0xFF202A58),
                                  Color(0xFF141A3C),
                                ],
                                stops: [0.0, 0.4, 0.8, 1.0],
                              ),
                            ),
                          ),
                        ),

                        // Spine Crease Line
                        Positioned(
                          left: 20,
                          top: 0,
                          bottom: 0,
                          width: 2,
                          child: Container(
                            color: const Color(0xFF161E42),
                          ),
                        ),

                        // Main Cover Art
                        Positioned.fill(
                          left: 22,
                          child: hasRealCover
                              ? _buildImageCover(coverPath!)
                              : _buildProcedural3DCover(bookWidth, bookHeight),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageCover(String path) {
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildProcedural3DCover(180, 240),
      );
    }
    if (kIsWeb) {
      return _buildProcedural3DCover(180, 240);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildProcedural3DCover(180, 240),
    );
  }

  Widget _buildProcedural3DCover(double w, double h) {
    return Container(
      color: const Color(0xFF222C5C),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 3D Embossed Title
          Text(
            title.isNotEmpty ? title : 'The Silent Patient',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFF6EEDB),
              letterSpacing: 0.5,
              shadows: const [
                Shadow(
                  color: Color(0x99000000),
                  offset: Offset(0, 2),
                  blurRadius: 3,
                ),
                Shadow(
                  color: Color(0x66FFFFFF),
                  offset: Offset(0, -1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),

          // Iconic Peach Keyhole with Leaves
          SizedBox(
            width: 90,
            height: 90,
            child: CustomPaint(
              painter: _ClayKeyholeArtPainter(),
            ),
          ),

          // 3D Embossed Author
          Text(
            author?.isNotEmpty == true ? author! : 'Alex Michaelides',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE8DCB8),
              letterSpacing: 0.3,
              shadows: const [
                Shadow(
                  color: Color(0x99000000),
                  offset: Offset(0, 1.5),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for the Peach Keyhole & Foliage motif on the book cover
class _ClayKeyholeArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Draw Symmetrical Foliage Leaves on left and right
    final leafPaint = Paint()
      ..color = const Color(0xFF43518F) // Lavender/blue clay leaf
      ..style = PaintingStyle.fill;

    final leafHighlightPaint = Paint()
      ..color = const Color(0xFF5D6CAE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    _drawBranch(canvas, cx - 22, cy, isLeft: true, leafPaint: leafPaint, highlightPaint: leafHighlightPaint);
    _drawBranch(canvas, cx + 22, cy, isLeft: false, leafPaint: leafPaint, highlightPaint: leafHighlightPaint);

    // Keyhole 3D Peach Motif
    final keyholePath = Path();
    const topR = 12.0;
    const keyholeTopY = 22.0;
    const keyholeBottomY = 66.0;

    // Top circle of keyhole
    keyholePath.addOval(Rect.fromCircle(center: Offset(cx, cy - 8), radius: topR));

    // Trapezoid trunk of keyhole
    final trunk = Path()
      ..moveTo(cx - 7, cy - 2)
      ..lineTo(cx + 7, cy - 2)
      ..lineTo(cx + 12, keyholeBottomY)
      ..lineTo(cx - 12, keyholeBottomY)
      ..close();

    final fullKeyhole = Path.combine(PathOperation.union, keyholePath, trunk);

    // Drop shadow under keyhole
    canvas.drawPath(
      fullKeyhole.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x660B1028)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Peach Body with gradient
    final peachGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFA68F),
        Color(0xFFEA8E77),
        Color(0xFFD67258),
      ],
    ).createShader(Rect.fromLTWH(cx - 15, keyholeTopY, 30, 50));

    canvas.drawPath(
      fullKeyhole,
      Paint()
        ..shader = peachGradient
        ..style = PaintingStyle.fill,
    );

    // Inner dark aperture
    final innerAperture = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy - 8), radius: 5.5));
    final innerTrunk = Path()
      ..moveTo(cx - 3, cy - 5)
      ..lineTo(cx + 3, cy - 5)
      ..lineTo(cx + 5, keyholeBottomY - 10)
      ..lineTo(cx - 5, keyholeBottomY - 10)
      ..close();
    final fullInner = Path.combine(PathOperation.union, innerAperture, innerTrunk);

    canvas.drawPath(
      fullInner,
      Paint()..color = const Color(0xFF1E2650),
    );

    // Top-left highlight rim on keyhole
    canvas.drawPath(
      fullKeyhole,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _drawBranch(
    Canvas canvas,
    double x,
    double y, {
    required bool isLeft,
    required Paint leafPaint,
    required Paint highlightPaint,
  }) {
    final offsets = [
      const Offset(0, -18),
      Offset(isLeft ? -6 : 6, -10),
      Offset(isLeft ? -10 : 10, 0),
      Offset(isLeft ? -8 : 8, 10),
      const Offset(0, 18),
    ];

    for (final off in offsets) {
      final lx = x + off.dx;
      final ly = y + off.dy;
      final leaf = Path()
        ..moveTo(lx, ly - 5)
        ..quadraticBezierTo(lx + (isLeft ? -7 : 7), ly, lx, ly + 5)
        ..quadraticBezierTo(lx + (isLeft ? -2 : 2), ly, lx, ly - 5);
      canvas.drawPath(leaf, leafPaint);
      canvas.drawPath(leaf, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Recessed Inset Clay Progress Bar matching reference design
class ClayRecessedProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;

  const ClayRecessedProgressBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  State<ClayRecessedProgressBar> createState() => _ClayRecessedProgressBarState();
}

class _ClayRecessedProgressBarState extends State<ClayRecessedProgressBar> {
  double? _dragRatio;

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.duration.inMilliseconds;
    final currentMs = _dragRatio != null
        ? (_dragRatio! * totalMs).toInt()
        : widget.position.inMilliseconds.clamp(0, totalMs > 0 ? totalMs : 0);

    final ratio = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final displayedPosition = Duration(milliseconds: currentMs);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final pillWidth = math.max(18.0, trackWidth * ratio);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final localX = details.localPosition.dx.clamp(0.0, trackWidth);
                final r = (localX / trackWidth).clamp(0.0, 1.0);
                widget.onSeek(Duration(milliseconds: (r * totalMs).toInt()));
              },
              onHorizontalDragUpdate: (details) {
                final localX = details.localPosition.dx.clamp(0.0, trackWidth);
                setState(() {
                  _dragRatio = (localX / trackWidth).clamp(0.0, 1.0);
                });
              },
              onHorizontalDragEnd: (details) {
                if (_dragRatio != null) {
                  final target = Duration(milliseconds: (_dragRatio! * totalMs).toInt());
                  _dragRatio = null;
                  widget.onSeek(target);
                }
              },
              child: Container(
                width: trackWidth,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6CEF7), // Recessed lavender track
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: const [
                    // Inset dark top shadow
                    BoxShadow(
                      color: Color(0x35473582),
                      offset: Offset(0, 2),
                      blurRadius: 3,
                    ),
                    // Inset white bottom highlight
                    BoxShadow(
                      color: Color(0x80FFFFFF),
                      offset: Offset(0, -1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Active 3D Coral/Peach Pill
                    Container(
                      width: pillWidth,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFA58F), // Light peach highlight
                            Color(0xFFE57457), // Warm coral
                          ],
                        ),
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40B5472F),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                          BoxShadow(
                            color: Color(0x80FFD6CC),
                            offset: Offset(0, -1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 6),

        // Timestamps underneath
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AudiobookDurationUtils.formatDuration(displayedPosition),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B2F63),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                AudiobookDurationUtils.formatDuration(widget.duration),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B2F63),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Transport Pill for -15s and +30s
class ClayTransportPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ClayTransportPill({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFDED8F6), // Lavender clay
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28473582),
            offset: Offset(0, 5),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF22174B),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Prominent 3D Purple Circular Play/Pause Button
class ClayPlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;

  const ClayPlayPauseButton({
    super.key,
    required this.isPlaying,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF4C2DB8), // Deep vibrant royal purple
        boxShadow: [
          BoxShadow(
            color: Color(0x55301880),
            offset: Offset(0, 10),
            blurRadius: 18,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Color(0x887E60EB),
            offset: Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : isPlaying
                    ? _buildPauseIcon()
                    : const Icon(
                        Icons.play_arrow_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
          ),
        ),
      ),
    );
  }

  Widget _buildPauseIcon() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 7,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// Secondary Action Pill (Chapters, Sleep Timer, Bookmark)
class ClayActionPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final bool hasRibbonBadge;
  final VoidCallback onTap;

  const ClayActionPill({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.hasRibbonBadge = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2255428F),
                offset: Offset(0, 4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.white,
                offset: Offset(-2, -2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 15,
                      color: const Color(0xFF67569E),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF22174B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bookmark Ribbon Tab Badge
        if (hasRibbonBadge)
          Positioned(
            top: -4,
            right: 8,
            child: Container(
              width: 12,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFFF07454), // Coral ribbon
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    offset: Offset(0, 2),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Floating Bottom Speed & Silence Skipping Card
class ClaySpeedSilenceCard extends StatelessWidget {
  final double speed;
  final bool silenceSkipping;
  final VoidCallback onSpeedTap;
  final VoidCallback onSilenceTap;

  const ClaySpeedSilenceCard({
    super.key,
    required this.speed,
    required this.silenceSkipping,
    required this.onSpeedTap,
    required this.onSilenceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 175,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF5), // Cream white
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2255428F),
            offset: Offset(0, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed button
          InkWell(
            onTap: onSpeedTap,
            child: Text(
              '${speed.toStringAsFixed(speed.truncateToDouble() == speed ? 1 : 2)}x',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF22174B),
              ),
            ),
          ),
          const SizedBox(height: 2),
          // Silence skipping toggle
          InkWell(
            onTap: onSilenceTap,
            child: Text(
              'Skip silence: ${silenceSkipping ? 'ON' : 'OFF'}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF5F547D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D Clay Puffy 4-point Star Sparkle
class ClaySparkle extends StatelessWidget {
  final double size;
  final Color color;
  final double rotation;

  const ClaySparkle({
    super.key,
    required this.size,
    required this.color,
    this.rotation = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size(size, size),
        painter: _ClayStarPainter(color: color),
      ),
    );
  }
}

class _ClayStarPainter extends CustomPainter {
  final Color color;

  _ClayStarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final starPath = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx, cy, w, cy)
      ..quadraticBezierTo(cx, cy, cx, h)
      ..quadraticBezierTo(cx, cy, 0, cy)
      ..quadraticBezierTo(cx, cy, cx, 0)
      ..close();

    // Drop Shadow
    canvas.drawPath(
      starPath.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x303B2A68)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Star Fill
    canvas.drawPath(
      starPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Top-left highlight
    canvas.drawPath(
      starPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

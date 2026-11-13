import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../network/api_config.dart';
import '../../shared/models/book.dart';
import 'clay_components.dart';

/// Tactile, upright 3D book cover supporting network/backend images, base64 data,
/// and graceful fallbacks to procedural pastel clay artwork.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.borderRadius = 10,
    this.fit = BoxFit.cover,
    this.elevation = 6,
  });

  final Book book;
  final double borderRadius;
  final BoxFit fit;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cover of ${book.title} by ${book.author}',
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5791).withValues(alpha: 0.18),
                blurRadius: elevation * 1.3,
                offset: Offset(0, elevation * 0.6),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.25),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildCoverContent(context),

                // Tactile left spine crease overlay for realistic 3D upright appearance
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.white.withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Subtle inner border for clay depth
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverContent(BuildContext context) {
    final rawUrl = book.effectiveCoverUrl;

    if (rawUrl == null || rawUrl.isEmpty) {
      return _buildStyledFallback();
    }

    // 1. Base64 / Data URI cover
    if (rawUrl.startsWith('data:image/') || rawUrl.contains(';base64,')) {
      try {
        final commaIdx = rawUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? rawUrl.substring(commaIdx + 1) : rawUrl;
        final Uint8List bytes = base64Decode(base64Str.replaceAll(RegExp(r'\s+'), ''));
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (_, __, ___) => _buildStyledFallback(),
          frameBuilder: (_, child, frame, wasSyncLoaded) {
            if (wasSyncLoaded || frame != null) return child;
            return _buildThemedLoadingPlaceholder();
          },
        );
      } catch (_) {
        return _buildStyledFallback();
      }
    }

    // 2. HTTP / HTTPS or relative URL
    String fullUrl = rawUrl;
    if (rawUrl.startsWith('/')) {
      final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
      if (rawUrl.startsWith('/api/v1/')) {
        final rootBase = base.replaceAll(RegExp(r'/api/v1$'), '');
        fullUrl = '$rootBase$rawUrl';
      } else {
        fullUrl = '$base$rawUrl';
      }
    }

    return Image.network(
      fullUrl,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildStyledFallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return _buildThemedLoadingPlaceholder();
      },
    );
  }

  Widget _buildThemedLoadingPlaceholder() {
    return Container(
      color: ClayColors.background,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              ClayColors.primaryPurple.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledFallback() {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: book.coverColors.isNotEmpty
                  ? book.coverColors
                  : const [Color(0xFF8873DA), Color(0xFF6550C7)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: w * 0.08,
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(w * 0.14, w * 0.1, w * 0.08, w * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      book.title,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: (w * 0.11).clamp(9.0, 15.0),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: w * 0.05),
                    Container(
                      height: 1.5,
                      width: w * 0.35,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    SizedBox(height: w * 0.05),
                    Text(
                      book.author.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: (w * 0.065).clamp(7.5, 11.0),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

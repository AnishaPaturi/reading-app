import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AudiobookCover extends StatelessWidget {
  final String? coverPath;
  final String title;
  final String? author;
  final double width;
  final double height;
  final double borderRadius;
  final bool showShadow;

  const AudiobookCover({
    super.key,
    required this.coverPath,
    required this.title,
    this.author,
    this.width = 120,
    this.height = 120,
    this.borderRadius = 8,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (coverPath != null && coverPath!.isNotEmpty) {
      if (coverPath!.startsWith('http://') || coverPath!.startsWith('https://')) {
        imageWidget = Image.network(
          coverPath!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallback(context),
        );
      } else if (!kIsWeb) {
        final file = File(coverPath!);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallback(context),
          );
        } else {
          imageWidget = _buildFallback(context);
        }
      } else {
        imageWidget = _buildFallback(context);
      }
    } else {
      imageWidget = _buildFallback(context);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final effectiveWidth = width.isFinite ? width : 120.0;
    final effectiveHeight = height.isFinite ? height : 120.0;
    final isCompact = effectiveWidth < 60 || effectiveHeight < 60;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5E35B1),
            Color(0xFF382761),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(isCompact ? 4 : 8),
      child: isCompact
          ? Center(
              child: Icon(
                Icons.headphones_rounded,
                color: Colors.white,
                size: (effectiveWidth * 0.45).clamp(14.0, 26.0),
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: (effectiveWidth - 16).clamp(40.0, 400.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.headphones_rounded,
                      color: Colors.white,
                      size: (effectiveWidth * 0.28).clamp(20.0, 48.0),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: (effectiveWidth * 0.09).clamp(10.0, 15.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (author != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: (effectiveWidth * 0.075).clamp(8.0, 11.0),
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

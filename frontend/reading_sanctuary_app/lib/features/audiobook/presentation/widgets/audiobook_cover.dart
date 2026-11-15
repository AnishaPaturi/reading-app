import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';

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
      } else {
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
                  color: Colors.black.withOpacity(0.35),
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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C1810),
            Color(0xFF1E140F),
          ],
        ),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.headphones_rounded,
            color: AppColors.gold.withOpacity(0.8),
            size: width * 0.28,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: AppColors.ivory,
              fontSize: (width * 0.09).clamp(10.0, 15.0),
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
                color: AppColors.gold.withOpacity(0.7),
                fontSize: (width * 0.075).clamp(8.0, 11.0),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

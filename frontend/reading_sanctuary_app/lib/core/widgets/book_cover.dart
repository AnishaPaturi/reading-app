import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/reader/presentation/providers/reader_provider.dart';
import '../network/api_config.dart';
import '../../shared/models/book.dart';
import 'clay_components.dart';

/// LRU in-memory cache for loaded cover image bytes to prevent re-fetching.
class CoverImageCache {
  static final Map<String, Uint8List> _cache = {};
  static final List<String> _order = [];
  static const int _maxSize = 120;

  static Uint8List? get(String url) => _cache[url];

  static void set(String url, Uint8List bytes) {
    if (_cache.containsKey(url)) {
      _order.remove(url);
      _order.add(url);
      _cache[url] = bytes;
      return;
    }
    if (_order.length >= _maxSize) {
      final oldest = _order.removeAt(0);
      _cache.remove(oldest);
    }
    _order.add(url);
    _cache[url] = bytes;
  }

  static void evict(String urlPrefix) {
    _cache.removeWhere((key, _) => key.contains(urlPrefix));
    _order.removeWhere((key) => key.contains(urlPrefix));
  }

  static void clear() {
    _cache.clear();
    _order.clear();
  }
}

/// Tactile, upright 3D book cover supporting authenticated network/backend images,
/// base64 data, and graceful fallbacks to procedural pastel clay artwork.
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

    // 2. HTTP / HTTPS or relative URL (authenticated retrieval)
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

    return _AuthenticatedCoverImage(
      url: fullUrl,
      fit: fit,
      fallbackBuilder: (_) => _buildStyledFallback(),
      loadingBuilder: (_) => _buildThemedLoadingPlaceholder(),
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

class _AuthenticatedCoverImage extends ConsumerStatefulWidget {
  final String url;
  final BoxFit fit;
  final WidgetBuilder fallbackBuilder;
  final WidgetBuilder loadingBuilder;

  const _AuthenticatedCoverImage({
    required this.url,
    required this.fit,
    required this.fallbackBuilder,
    required this.loadingBuilder,
  });

  @override
  ConsumerState<_AuthenticatedCoverImage> createState() => _AuthenticatedCoverImageState();
}

class _AuthenticatedCoverImageState extends ConsumerState<_AuthenticatedCoverImage> {
  Uint8List? _bytes;
  bool _isLoading = false;
  bool _hasError = false;
  String? _loadedUrl;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _AuthenticatedCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final targetUrl = widget.url;
    _loadedUrl = targetUrl;

    // Check memory cache first
    final cached = CoverImageCache.get(targetUrl);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _bytes = cached;
          _isLoading = false;
          _hasError = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _bytes = null;
      });
    }

    try {
      final token = ref.read(authTokenProvider) ?? ref.read(authNotifierProvider).user?.token;
      final headers = <String, String>{
        'Accept': 'image/*',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(Uri.parse(targetUrl), headers: headers);
      if (_loadedUrl != targetUrl || !mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300 && response.bodyBytes.isNotEmpty) {
        CoverImageCache.set(targetUrl, response.bodyBytes);
        setState(() {
          _bytes = response.bodyBytes;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (_loadedUrl == targetUrl && mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(authTokenProvider, (previous, next) {
      if (previous != next && next != null && next.isNotEmpty && (_hasError || _bytes == null)) {
        _loadImage();
      }
    });

    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => widget.fallbackBuilder(context),
      );
    }
    if (_hasError) {
      return widget.fallbackBuilder(context);
    }
    if (_isLoading) {
      return widget.loadingBuilder(context);
    }
    return widget.loadingBuilder(context);
  }
}

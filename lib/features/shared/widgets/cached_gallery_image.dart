import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network image with memory cache + shimmer placeholder so gallery
/// covers don't flicker when navigating between catalogs.
class CachedGalleryImage extends StatelessWidget {
  const CachedGalleryImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.placeholderColor,
  });

  final String imageUrl;
  final Widget fallback;
  final BoxFit fit;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    // On web, let the browser own the image request and its HTTP cache. The
    // web implementation of cached_network_image can dispose its temporary
    // resource when a route is removed, leaving the same URL blank when the
    // catalog is mounted again. A normal NetworkImage remains reusable across
    // Home -> Detail -> Products navigation.
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) return child;
          return _placeholder();
        },
        errorBuilder: (_, _, _) => fallback,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      memCacheWidth: 900,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => fallback,
    );
  }

  Widget _placeholder() {
    return Container(
      color: placeholderColor ?? Colors.black.withValues(alpha: 0.05),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}

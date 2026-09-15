import 'package:cached_network_image/cached_network_image.dart';
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
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      memCacheWidth: 900,
      placeholder: (_, _) => Container(
        color: placeholderColor ?? Colors.black.withValues(alpha: 0.05),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      errorWidget: (_, _, _) => fallback,
    );
  }
}

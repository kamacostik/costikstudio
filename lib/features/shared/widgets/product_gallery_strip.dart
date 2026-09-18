import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/shared/widgets/cached_gallery_image.dart';
import 'package:flutter/material.dart';

/// Public gallery strip: cover + tap-to-switch thumbnails.
class ProductGalleryStrip extends StatefulWidget {
  const ProductGalleryStrip({super.key, required this.images});

  final List<ProductImage> images;

  @override
  State<ProductGalleryStrip> createState() => _ProductGalleryStripState();
}

class _ProductGalleryStripState extends State<ProductGalleryStrip> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final current = images[_index.clamp(0, images.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedGalleryImage(
              imageUrl: current.imageUrl,
              fallback: Container(
                color: Colors.black.withValues(alpha: 0.06),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_rounded,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final selected = i == _index;
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    width: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF2563EB)
                            : Colors.black.withValues(alpha: 0.1),
                        width: selected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: CachedGalleryImage(
                        imageUrl: images[i].imageUrl,
                        fallback: Container(
                          color: Colors.black.withValues(alpha: 0.06),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

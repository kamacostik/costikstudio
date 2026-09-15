import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class PublicProductImageRepository {
  Future<Map<String, List<ProductImage>>> loadImagesByProductId();
}

class ProductGalleryLoader {
  const ProductGalleryLoader({
    this.repository = const SupabasePublicProductImageRepository(),
  });

  final PublicProductImageRepository repository;

  Future<List<ProductItem>> attachImages(List<ProductItem> products) async {
    final imagesByProductId = await repository.loadImagesByProductId();
    return products
        .map(
          (product) => product.copyWith(
            images: _catalogImagesFor(
              imagesByProductId[product.id] ?? product.images,
            ),
          ),
        )
        .toList(growable: false);
  }

  Future<List<ProductItem>> attachAllImages(List<ProductItem> products) async {
    final imagesByProductId = await repository.loadImagesByProductId();
    return products
        .map(
          (product) => product.copyWith(
            images: imagesByProductId[product.id] ?? product.images,
          ),
        )
        .toList(growable: false);
  }

  List<ProductImage> _catalogImagesFor(List<ProductImage> images) {
    if (images.isEmpty) return images;
    for (final image in images) {
      if (image.isCover && image.isActive) return [image];
    }
    for (final image in images) {
      if (image.isActive) return [image];
    }
    return const [];
  }
}

class SupabasePublicProductImageRepository
    implements PublicProductImageRepository {
  const SupabasePublicProductImageRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  @override
  Future<Map<String, List<ProductImage>>> loadImagesByProductId() async {
    if (!SupabaseConfig.isConfigured) return const {};

    final rows = await _supabase
        .from('product_images')
        .select(
          'id, product_id, image_url, title, alt_text, sort_order, is_cover, is_active',
        )
        .eq('is_active', true)
        .order('product_id')
        .order('sort_order')
        .order('created_at');

    final grouped = <String, List<ProductImage>>{};
    for (final row in rows as List) {
      final image = _imageFromRow(Map<String, dynamic>.from(row as Map));
      grouped.putIfAbsent(image.productId, () => []).add(image);
    }
    return grouped;
  }

  ProductImage _imageFromRow(Map<String, dynamic> row) {
    return ProductImage(
      id: row['id'] as String,
      productId: row['product_id'] as String,
      imageUrl: row['image_url'] as String,
      title: row['title'] as String?,
      altText: row['alt_text'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      isCover: row['is_cover'] as bool? ?? false,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

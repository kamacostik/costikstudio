import 'package:costikstudio/core/data/product_gallery_loader.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attaches only cover images to catalog products', () async {
    final loader = ProductGalleryLoader(
      repository: _FakePublicProductImageRepository({
        'costik-iptv': const [
          ProductImage(
            id: 'img-1',
            productId: 'costik-iptv',
            imageUrl: 'https://example.com/iptv.png',
            isCover: true,
          ),
          ProductImage(
            id: 'img-2',
            productId: 'costik-iptv',
            imageUrl: 'https://example.com/iptv-gallery.png',
          ),
        ],
      }),
    );

    final products = await loader.attachImages(const [
      ProductItem(
        id: 'costik-iptv',
        name: 'Costik IPTV',
        tagline: 'IPTV',
        description: 'IPTV',
        category: ProductCategory.hospitality,
        status: ProductStatus.beta,
        accentHex: 0xFF0EA5E9,
        features: [],
      ),
    ]);

    expect(products.single.images, hasLength(1));
    expect(
      products.single.coverImage?.imageUrl,
      'https://example.com/iptv.png',
    );
  });

  test('attaches all active images to detail products', () async {
    final loader = ProductGalleryLoader(
      repository: _FakePublicProductImageRepository({
        'costik-iptv': const [
          ProductImage(
            id: 'img-1',
            productId: 'costik-iptv',
            imageUrl: 'https://example.com/iptv.png',
            isCover: true,
          ),
          ProductImage(
            id: 'img-2',
            productId: 'costik-iptv',
            imageUrl: 'https://example.com/iptv-gallery.png',
          ),
        ],
      }),
    );

    final products = await loader.attachAllImages(const [
      ProductItem(
        id: 'costik-iptv',
        name: 'Costik IPTV',
        tagline: 'IPTV',
        description: 'IPTV',
        category: ProductCategory.hospitality,
        status: ProductStatus.beta,
        accentHex: 0xFF0EA5E9,
        features: [],
      ),
    ]);

    expect(products.single.images, hasLength(2));
  });
}

class _FakePublicProductImageRepository
    implements PublicProductImageRepository {
  _FakePublicProductImageRepository(this.imagesByProductId);

  final Map<String, List<ProductImage>> imagesByProductId;

  @override
  Future<Map<String, List<ProductImage>>> loadImagesByProductId() async {
    return imagesByProductId;
  }
}

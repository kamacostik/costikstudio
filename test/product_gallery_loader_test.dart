import 'package:costikstudio/core/data/product_gallery_loader.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(ProductGalleryLoader.clearCacheForTests);

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

  test(
    'keeps last loaded images when a recreated loader receives empty rows',
    () async {
      final firstLoader = ProductGalleryLoader(
        repository: _FakePublicProductImageRepository({
          'costik-iptv': const [
            ProductImage(
              id: 'img-1',
              productId: 'costik-iptv',
              imageUrl: 'https://example.com/iptv.png',
              isCover: true,
            ),
          ],
        }),
      );
      await firstLoader.attachAllImages(_singleProduct());

      final recreatedLoader = ProductGalleryLoader(
        repository: _FakePublicProductImageRepository(const {}),
      );
      final products = await recreatedLoader.attachAllImages(_singleProduct());

      expect(
        products.single.coverImage?.imageUrl,
        'https://example.com/iptv.png',
      );
    },
  );

  test(
    'merges partial refresh rows without dropping cached product images',
    () async {
      final firstLoader = ProductGalleryLoader(
        repository: _FakePublicProductImageRepository({
          'costik-iptv': const [
            ProductImage(
              id: 'img-1',
              productId: 'costik-iptv',
              imageUrl: 'https://example.com/iptv.png',
              isCover: true,
            ),
          ],
          'digital-signage': const [
            ProductImage(
              id: 'img-2',
              productId: 'digital-signage',
              imageUrl: 'https://example.com/signage.png',
              isCover: true,
            ),
          ],
        }),
      );
      await firstLoader.attachAllImages(_twoProducts());

      final partialLoader = ProductGalleryLoader(
        repository: _FakePublicProductImageRepository({
          'costik-iptv': const [
            ProductImage(
              id: 'img-1b',
              productId: 'costik-iptv',
              imageUrl: 'https://example.com/iptv-new.png',
              isCover: true,
            ),
          ],
        }),
      );
      final products = await partialLoader.attachAllImages(_twoProducts());

      expect(
        products[0].coverImage?.imageUrl,
        'https://example.com/iptv-new.png',
      );
      expect(
        products[1].coverImage?.imageUrl,
        'https://example.com/signage.png',
      );
    },
  );
}

List<ProductItem> _singleProduct() {
  return const [
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
  ];
}

List<ProductItem> _twoProducts() {
  return const [
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
    ProductItem(
      id: 'digital-signage',
      name: 'Digital Signage',
      tagline: 'Signage',
      description: 'Signage',
      category: ProductCategory.hospitality,
      status: ProductStatus.beta,
      accentHex: 0xFF0EA5E9,
      features: [],
    ),
  ];
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

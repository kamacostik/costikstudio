import 'package:costikstudio/core/data/product_gallery_loader.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/products/cubit/product_catalog_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps cached product images when refresh fails', () async {
    final repository = _SwitchingGalleryRepository();
    final cubit = ProductCatalogCubit(
      galleryLoader: ProductGalleryLoader(repository: repository),
    );

    await cubit.load();
    expect(cubit.state.productById('costik-iptv')?.activeImages, hasLength(1));

    repository.shouldFail = true;
    await cubit.load(forceRefresh: true);

    expect(cubit.state.productById('costik-iptv')?.activeImages, hasLength(1));
    expect(cubit.state.errorMessage, isNotNull);
  });
}

class _SwitchingGalleryRepository implements PublicProductImageRepository {
  bool shouldFail = false;

  @override
  Future<Map<String, List<ProductImage>>> loadImagesByProductId() async {
    if (shouldFail) throw StateError('network failed');
    return {
      'costik-iptv': const [
        ProductImage(
          id: 'img-1',
          productId: 'costik-iptv',
          imageUrl: 'https://example.com/iptv-cover.png',
          isCover: true,
        ),
      ],
    };
  }
}

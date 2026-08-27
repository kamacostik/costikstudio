import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dummy catalog contains core CostikStudio products', () {
    expect(dummyProducts.map((product) => product.id), contains('cospos'));
    expect(
      dummyProducts.map((product) => product.id),
      contains('cospos-kasir'),
    );
    expect(dummyProducts.map((product) => product.id), contains('costik-iptv'));
    expect(
      dummyProducts.map((product) => product.id),
      contains('arisan-online'),
    );
  });

  test('admin products include web admin URLs', () {
    final adminProducts = dummyProducts.where((product) => product.hasAdmin);

    expect(adminProducts.length, greaterThanOrEqualTo(3));
    expect(
      adminProducts.every(
        (product) => product.adminUrl!.contains('costikstudio.com'),
      ),
      isTrue,
    );
  });

  test('free app catalog exposes download URLs', () {
    final freeApps = productsByCategory(ProductCategory.freeApp);

    expect(freeApps, isNotEmpty);
    expect(freeApps.every((product) => product.hasDownload), isTrue);
  });
}

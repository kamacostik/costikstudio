import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dummy catalog focuses on four CostikStudio products', () {
    final productIds = dummyProducts.map((product) => product.id).toList();

    expect(productIds, hasLength(4));
    expect(productIds, contains('costik-iptv'));
    expect(productIds, contains('digital-signage'));
    expect(productIds, contains('coshris'));
    expect(productIds, contains('smart-inv'));
    expect(productIds, isNot(contains('cospos')));
    expect(productIds, isNot(contains('scoreboard-online')));
  });

  test('admin products include web admin URLs', () {
    final adminProducts = dummyProducts.where((product) => product.hasAdmin);

    expect(adminProducts.length, greaterThanOrEqualTo(4));
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
    expect(freeApps.map((product) => product.id), contains('smart-inv'));
  });
}

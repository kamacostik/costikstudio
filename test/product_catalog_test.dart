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
        (product) => product.adminUrl!.startsWith('https://'),
      ),
      isTrue,
    );
    expect(
      dummyProducts
          .firstWhere((product) => product.id == 'costik-iptv')
          .adminUrl,
      'https://admin-ip-tv.pages.dev/',
    );
  });

  test('Costik IPTV catalog highlights admin IPTV hospitality modules', () {
    final iptv = dummyProducts.firstWhere(
      (product) => product.id == 'costik-iptv',
    );

    expect(iptv.features.length, greaterThanOrEqualTo(8));
    expect(
      iptv.features,
      contains('Live TV channel and video playlist management'),
    );
    expect(
      iptv.features,
      contains('Room, device, and guest profile management'),
    );
    expect(
      iptv.features,
      contains('Restaurant menu, category, and incoming order workflow'),
    );
    expect(
      iptv.features,
      contains(
        'Hotel information modules for facilities, dining, convention, maps, Wi-Fi, and about pages',
      ),
    );
    expect(
      iptv.features,
      contains(
        'Guest request tools: service call, reviews, promo, and message/content menus',
      ),
    );
  });

  test('free app catalog exposes download URLs', () {
    final freeApps = productsByCategory(ProductCategory.freeApp);

    expect(freeApps, isNotEmpty);
    expect(freeApps.every((product) => product.hasDownload), isTrue);
    expect(freeApps.map((product) => product.id), contains('smart-inv'));
  });
}

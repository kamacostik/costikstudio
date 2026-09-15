import 'package:costikstudio/core/data/product_gallery_loader.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/apps/view/apps_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('apps catalog card shows uploaded IPTV cover image', (
    tester,
  ) async {
    final loader = ProductGalleryLoader(
      repository: _FakeGallery({
        'costik-iptv': const [
          ProductImage(
            id: 'img-1',
            productId: 'costik-iptv',
            imageUrl: 'https://example.com/iptv-cover.png',
            isCover: true,
          ),
        ],
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: AppsPage(galleryLoader: loader)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
  });
}

class _FakeGallery implements PublicProductImageRepository {
  _FakeGallery(this.imagesByProductId);

  final Map<String, List<ProductImage>> imagesByProductId;

  @override
  Future<Map<String, List<ProductImage>>> loadImagesByProductId() async {
    return imagesByProductId;
  }
}

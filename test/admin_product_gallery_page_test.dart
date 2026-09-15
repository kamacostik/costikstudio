import 'dart:typed_data';

import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/admin_product_gallery/view/admin_product_gallery_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin product gallery page shows upload controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminProductGalleryPage(repository: _FakeGalleryRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product Gallery'), findsOneWidget);
    expect(find.text('Pilih Produk'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.text('Set as cover'), findsWidgets);
  });
}

class _FakeGalleryRepository implements ProductGalleryRepository {
  @override
  Future<List<ProductImage>> listImages(String productId) async {
    return [
      ProductImage(
        id: 'image-1',
        productId: productId,
        imageUrl: 'https://example.com/cover.png',
        title: 'Cover preview',
        isCover: true,
      ),
    ];
  }

  @override
  Future<void> uploadImage({
    required String productId,
    required String fileName,
    required Uint8List bytes,
    required bool isCover,
  }) async {}

  @override
  Future<void> setCover(String productId, String imageId) async {}

  @override
  Future<void> deleteImage(String imageId) async {}
}

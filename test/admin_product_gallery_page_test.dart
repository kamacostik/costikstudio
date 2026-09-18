import 'dart:async';
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Product Gallery'), findsOneWidget);
    expect(find.text('Pilih Produk'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.text('Set as cover'), findsWidgets);
    expect(find.text('Nonaktifkan'), findsOneWidget);
    expect(find.text('Aktifkan'), findsOneWidget);
  });

  testWidgets('admin product gallery shows blocking loading overlay', (
    tester,
  ) async {
    final repository = _FakeGalleryRepository();
    final completer = Completer<List<ProductImage>>();
    repository.listCompleter = completer;

    await tester.pumpWidget(
      MaterialApp(home: AdminProductGalleryPage(repository: repository)),
    );
    await tester.pump();

    expect(find.text('Memproses...'), findsOneWidget);
    expect(
      find.text('Mohon tunggu, proses gallery sedang berjalan.'),
      findsOneWidget,
    );

    completer.complete(repository.images);
    await tester.pump();
  });
}

class _FakeGalleryRepository implements ProductGalleryRepository {
  Completer<List<ProductImage>>? listCompleter;

  List<ProductImage> get images => const [
    ProductImage(
      id: 'image-1',
      productId: 'costik-iptv',
      imageUrl: 'https://example.com/cover.png',
      title: 'Cover preview',
      isCover: true,
    ),
    ProductImage(
      id: 'image-2',
      productId: 'costik-iptv',
      imageUrl: 'https://example.com/hidden.png',
      title: 'Hidden preview',
      isActive: false,
    ),
  ];

  @override
  Future<List<ProductImage>> listImages(String productId) async {
    final completer = listCompleter;
    if (completer != null) return completer.future;
    return images;
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
  Future<void> setImageActive(String imageId, bool isActive) async {}
}

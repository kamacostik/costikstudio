import 'dart:typed_data';

import 'package:costikstudio/features/admin_product_gallery/data/gallery_image_compressor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('compresses large uploads below original size and bounds', () {
    final original = img.Image(width: 2400, height: 1800);
    for (var y = 0; y < original.height; y += 4) {
      for (var x = 0; x < original.width; x += 4) {
        original.setPixelRgba(x, y, x % 256, y % 256, 128, 255);
      }
    }
    final originalBytes = Uint8List.fromList(
      img.encodeJpg(original, quality: 100),
    );

    final compressed = compressGalleryImageBytes(originalBytes);

    expect(compressed.length, lessThan(originalBytes.length));
    final decoded = img.decodeImage(compressed)!;
    expect(decoded.width <= 1920, isTrue);
    expect(decoded.height <= 1920, isTrue);
  });

  test('returns original bytes when input is not an image', () {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);

    expect(compressGalleryImageBytes(bytes), bytes);
  });
}

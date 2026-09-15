import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Max dimension (longest side) for gallery uploads, in pixels.
const galleryImageMaxDimension = 1600;

/// JPEG quality for compressed gallery uploads.
const galleryImageJpegQuality = 80;

/// Compresses raw image bytes for gallery upload: downscales large images
/// so the longest side is at most [galleryImageMaxDimension] and re-encodes
/// as JPEG at [galleryImageJpegQuality]. Returns the input unchanged when
/// it cannot be decoded as an image.
Uint8List compressGalleryImageBytes(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } on Object {
    return bytes;
  }
  if (decoded == null) return bytes;

  var image = decoded;
  final longestSide = image.width > image.height ? image.width : image.height;
  if (longestSide > galleryImageMaxDimension) {
    image = img.copyResize(
      image,
      width: image.width >= image.height ? galleryImageMaxDimension : null,
      height: image.height > image.width ? galleryImageMaxDimension : null,
    );
  }

  return Uint8List.fromList(
    img.encodeJpg(image, quality: galleryImageJpegQuality),
  );
}

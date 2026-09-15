import 'dart:typed_data';

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/admin_product_gallery/data/gallery_image_compressor.dart';
import 'package:costikstudio/features/shared/widgets/cached_gallery_image.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProductGalleryPage extends StatefulWidget {
  const AdminProductGalleryPage({super.key, this.repository});

  final ProductGalleryRepository? repository;

  @override
  State<AdminProductGalleryPage> createState() =>
      _AdminProductGalleryPageState();
}

class _AdminProductGalleryPageState extends State<AdminProductGalleryPage> {
  late final ProductGalleryRepository _repository =
      widget.repository ?? const SupabaseProductGalleryRepository();
  String _selectedProductId = dummyProducts.first.id;
  bool _loading = false;
  String? _message;
  List<ProductImage> _images = const [];

  ProductItem get _selectedProduct => dummyProducts.firstWhere(
    (product) => product.id == _selectedProductId,
    orElse: () => dummyProducts.first,
  );

  ProductImage? get _coverImage {
    for (final image in _images) {
      if (image.isCover) return image;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() => _loading = true);
    try {
      final images = await _repository.listImages(_selectedProductId);
      if (!mounted) return;
      setState(() {
        _images = images;
        _message = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Gagal memuat gallery: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _uploadImage() async {
    final picked = await FilePicker.pickFiles(type: FileType.image);
    if (picked.isEmpty) return;
    final file = picked.single;
    final bytes = await file.readAsBytes();

    setState(() {
      _loading = true;
      _message = 'Mengupload image...';
    });
    try {
      await _repository.uploadImage(
        productId: _selectedProductId,
        fileName: file.name,
        bytes: bytes,
        isCover: _images.isEmpty,
      );
      await _loadImages();
      if (!mounted) return;
      setState(() => _message = 'Image berhasil diupload.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = 'Upload gagal: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setCover(ProductImage image) async {
    setState(() => _loading = true);
    try {
      await _repository.setCover(image.productId, image.id);
      await _loadImages();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteImage(ProductImage image) async {
    setState(() => _loading = true);
    try {
      await _repository.deleteImage(image.id);
      await _loadImages();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ResponsiveSection(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ADMIN · PRODUCT GALLERY',
              style: TextStyle(
                color: CostikStudioTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Product Gallery',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload dan kelola screenshot aplikasi yang tampil di card produk member.',
              style: TextStyle(color: CostikStudioTheme.slate, height: 1.5),
            ),
            const SizedBox(height: 20),
            _GalleryControlCard(
              loading: _loading,
              message: _message,
              product: _selectedProduct,
              selectedProductId: _selectedProductId,
              totalImages: _images.length,
              hasCover: _coverImage != null,
              onProductChanged: (value) {
                if (value == null) return;
                setState(() => _selectedProductId = value);
                _loadImages();
              },
              onUpload: _uploadImage,
            ),
            const SizedBox(height: 18),
            if (_images.isEmpty && !_loading)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: CostikStudioTheme.primary.withValues(
                            alpha: 0.10,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: CostikStudioTheme.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Belum ada image untuk produk ini.',
                              style: TextStyle(
                                color: CostikStudioTheme.navy,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Upload screenshot pertama, otomatis menjadi cover produk.',
                              style: TextStyle(
                                color: CostikStudioTheme.slate,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 720;
                  final cardWidth = isWide
                      ? (constraints.maxWidth - 14) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (final image in _images)
                        SizedBox(
                          width: cardWidth,
                          child: _ProductGalleryImageCard(
                            image: image,
                            onSetCover: () => _setCover(image),
                            onDelete: () => _deleteImage(image),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryControlCard extends StatelessWidget {
  const _GalleryControlCard({
    required this.loading,
    required this.message,
    required this.product,
    required this.selectedProductId,
    required this.totalImages,
    required this.hasCover,
    required this.onProductChanged,
    required this.onUpload,
  });

  final bool loading;
  final String? message;
  final ProductItem product;
  final String selectedProductId;
  final int totalImages;
  final bool hasCover;
  final ValueChanged<String?> onProductChanged;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 860;
            final selector = SizedBox(
              width: isWide ? 300 : double.infinity,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: selectedProductId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Produk',
                  border: OutlineInputBorder(),
                ),
                items: dummyProducts
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(growable: false),
                onChanged: loading ? null : onProductChanged,
              ),
            );
            final meta = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: CostikStudioTheme.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalImages image · ${hasCover ? 'cover siap' : 'belum ada cover'}',
                  style: const TextStyle(
                    color: CostikStudioTheme.slate,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: loading ? null : onUpload,
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('Upload Image'),
                ),
                if (loading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isWide)
                  Row(
                    children: [
                      selector,
                      const SizedBox(width: 18),
                      meta,
                      const SizedBox(width: 18),
                      actions,
                    ],
                  )
                else ...[
                  selector,
                  const SizedBox(height: 14),
                  meta,
                  const SizedBox(height: 14),
                  actions,
                ],
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    message!,
                    style: const TextStyle(
                      color: CostikStudioTheme.slate,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

abstract class ProductGalleryRepository {
  Future<List<ProductImage>> listImages(String productId);

  Future<void> uploadImage({
    required String productId,
    required String fileName,
    required Uint8List bytes,
    required bool isCover,
  });

  Future<void> setCover(String productId, String imageId);

  Future<void> deleteImage(String imageId);
}

class SupabaseProductGalleryRepository implements ProductGalleryRepository {
  const SupabaseProductGalleryRepository({this.client});

  static const bucket = 'product-images';
  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  @override
  Future<List<ProductImage>> listImages(String productId) async {
    final rows = await _supabase
        .from('product_images')
        .select(
          'id, product_id, image_url, title, alt_text, sort_order, is_cover, is_active',
        )
        .eq('product_id', productId)
        .order('sort_order')
        .order('created_at');

    return (rows as List)
        .map((row) => _imageFromRow(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  @override
  Future<void> uploadImage({
    required String productId,
    required String fileName,
    required Uint8List bytes,
    required bool isCover,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-');
    final path =
        '$productId/${DateTime.now().millisecondsSinceEpoch}-$safeName';
    final compressedBytes = compressGalleryImageBytes(bytes);
    await _supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          compressedBytes,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );
    final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);
    await _supabase.from('product_images').insert({
      'product_id': productId,
      'image_url': publicUrl,
      'title': fileName,
      'alt_text': fileName,
      'sort_order': DateTime.now().millisecondsSinceEpoch,
      'is_cover': isCover,
      'is_active': true,
    });
  }

  @override
  Future<void> setCover(String productId, String imageId) async {
    await _supabase
        .from('product_images')
        .update({'is_cover': false})
        .eq('product_id', productId);
    await _supabase
        .from('product_images')
        .update({'is_cover': true})
        .eq('id', imageId);
  }

  @override
  Future<void> deleteImage(String imageId) async {
    await _supabase
        .from('product_images')
        .update({'is_active': false, 'is_cover': false})
        .eq('id', imageId);
  }

  ProductImage _imageFromRow(Map<String, dynamic> row) {
    return ProductImage(
      id: row['id'] as String,
      productId: row['product_id'] as String,
      imageUrl: row['image_url'] as String,
      title: row['title'] as String?,
      altText: row['alt_text'] as String?,
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      isCover: row['is_cover'] as bool? ?? false,
      isActive: row['is_active'] as bool? ?? true,
    );
  }
}

class _ProductGalleryImageCard extends StatelessWidget {
  const _ProductGalleryImageCard({
    required this.image,
    required this.onSetCover,
    required this.onDelete,
  });

  final ProductImage image;
  final VoidCallback onSetCover;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedGalleryImage(
                  imageUrl: image.imageUrl,
                  placeholderColor: CostikStudioTheme.primary.withValues(
                    alpha: 0.08,
                  ),
                  fallback: Container(
                    color: CostikStudioTheme.primary.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: CostikStudioTheme.slate,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: image.isCover
                        ? CostikStudioTheme.navy
                        : Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        image.isCover
                            ? Icons.star_rounded
                            : Icons.image_outlined,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        image.isCover ? 'Cover' : 'Gallery',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  image.title ?? image.imageUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CostikStudioTheme.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  image.isActive ? 'Tampil di produk' : 'Disembunyikan',
                  style: const TextStyle(
                    color: CostikStudioTheme.slate,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: image.isCover ? null : onSetCover,
                        icon: const Icon(Icons.star_outline_rounded, size: 16),
                        label: const Text('Set as cover'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Hide',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

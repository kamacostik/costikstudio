import 'dart:typed_data';

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
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
        padding: const EdgeInsets.fromLTRB(24, 56, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Gallery',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 10),
            const Text(
              'Upload dan kelola screenshot aplikasi yang tampil di card produk member.',
              style: TextStyle(color: CostikStudioTheme.slate, height: 1.5),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedProductId,
                        decoration: const InputDecoration(
                          labelText: 'Pilih Produk',
                          border: OutlineInputBorder(),
                        ),
                        items: dummyProducts
                            .map(
                              (product) => DropdownMenuItem(
                                value: product.id,
                                child: Text(product.name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _loading
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _selectedProductId = value);
                                _loadImages();
                              },
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _loading ? null : _uploadImage,
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Upload Image'),
                    ),
                    if (_loading) const CircularProgressIndicator(),
                    if (_message != null)
                      Text(
                        _message!,
                        style: const TextStyle(color: CostikStudioTheme.slate),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_images.isEmpty && !_loading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Belum ada image untuk produk ini.'),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: _images
                        .map(
                          (image) => SizedBox(
                            width: isWide
                                ? (constraints.maxWidth - 32) / 3
                                : constraints.maxWidth,
                            child: _ProductGalleryImageCard(
                              image: image,
                              onSetCover: () => _setCover(image),
                              onDelete: () => _deleteImage(image),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
          ],
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
    await _supabase.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
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
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  image.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: CostikStudioTheme.primary.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      color: CostikStudioTheme.slate,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    image.title ?? image.imageUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                if (image.isCover)
                  const Chip(
                    label: Text('Cover'),
                    avatar: Icon(Icons.star_rounded, size: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: image.isCover ? null : onSetCover,
                  icon: const Icon(Icons.star_outline_rounded, size: 16),
                  label: const Text('Set as cover'),
                ),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Hide'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum ProductCategory { business, hospitality, productivity, freeApp }

enum ProductStatus { live, beta, comingSoon }

class ProductImage {
  const ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    this.title,
    this.altText,
    this.sortOrder = 0,
    this.isCover = false,
    this.isActive = true,
  });

  final String id;
  final String productId;
  final String imageUrl;
  final String? title;
  final String? altText;
  final int sortOrder;
  final bool isCover;
  final bool isActive;
}

class ProductItem {
  const ProductItem({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    required this.status,
    required this.accentHex,
    required this.features,
    this.adminUrl,
    this.downloadUrl,
    this.productUrl,
    this.images = const [],
    this.isFree = false,
    this.isNew = false,
    this.isHidden = false,
  });

  final String id;
  final String name;
  final String tagline;
  final String description;
  final ProductCategory category;
  final ProductStatus status;
  final int accentHex;
  final List<String> features;
  final String? adminUrl;
  final String? downloadUrl;
  final String? productUrl;
  final List<ProductImage> images;
  final bool isFree;
  final bool isNew;
  final bool isHidden;

  bool get hasAdmin => adminUrl != null && adminUrl!.isNotEmpty;
  bool get hasDownload => downloadUrl != null && downloadUrl!.isNotEmpty;

  List<ProductImage> get activeImages {
    final active = images.where((image) => image.isActive).toList();
    active.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return active;
  }

  ProductImage? get coverImage {
    final active = activeImages;
    if (active.isEmpty) return null;
    for (final image in active) {
      if (image.isCover) return image;
    }
    return active.first;
  }

  ProductItem copyWith({List<ProductImage>? images}) {
    return ProductItem(
      id: id,
      name: name,
      tagline: tagline,
      description: description,
      category: category,
      status: status,
      accentHex: accentHex,
      features: features,
      adminUrl: adminUrl,
      downloadUrl: downloadUrl,
      productUrl: productUrl,
      images: images ?? this.images,
      isFree: isFree,
      isNew: isNew,
      isHidden: isHidden,
    );
  }
}

enum ProductCategory { business, hospitality, productivity, freeApp }

enum ProductStatus { live, beta, comingSoon }

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
    this.isFree = false,
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
  final bool isFree;

  bool get hasAdmin => adminUrl != null && adminUrl!.isNotEmpty;
  bool get hasDownload => downloadUrl != null && downloadUrl!.isNotEmpty;
}

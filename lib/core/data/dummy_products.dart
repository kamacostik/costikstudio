import 'package:costikstudio/core/models/product_item.dart';

const dummyProducts = <ProductItem>[
  ProductItem(
    id: 'costik-iptv',
    name: 'Costik IPTV',
    tagline: 'Hotel IPTV, live TV, and guest information system.',
    description: 'An IPTV platform for hotels and hospitality environments with live TV, cloud content, guest information, and lightweight online/offline monitoring.',
    category: ProductCategory.hospitality,
    status: ProductStatus.beta,
    accentHex: 0xFF0EA5E9,
    productUrl: 'https://iptv.costikstudio.com',
    adminUrl: 'https://admin.iptv.costikstudio.com',
    features: [
      'Live TV and guest room entertainment flow',
      'Hotel information, menu, and content management',
      'Online/offline device visibility for rooms',
    ],
  ),
  ProductItem(
    id: 'digital-signage',
    name: 'Digital Signage',
    tagline: 'Event schedule board and fullscreen video signage for hotels.',
    description: 'A subscription-based digital signage platform for hotels and public screens. Manage hotel profile/logo, Daily Event schedules, media library, multi-video playlists, device pairing, and per-device display mode from CostikStudio Web Admin.',
    category: ProductCategory.business,
    status: ProductStatus.beta,
    accentHex: 0xFF2563EB,
    productUrl: 'https://signage.costikstudio.com',
    adminUrl: 'https://admin.signage.costikstudio.com',
    features: [
      'Daily Event board with date, start/end time, room, floor, auto-slide, and manual OK refresh',
      'Fullscreen video player with hotel logo overlay and multi-video playlist order',
      'TV/browser client pairing with 6-digit code, device quota, online status, and per-device mode',
    ],
  ),
  ProductItem(
    id: 'coshris',
    name: 'CosHRIS',
    tagline: 'HR, staff attendance, shift, and employee operations system.',
    description: 'An HRIS platform for employee profiles, attendance, shifts, leave tracking, and basic HR operations for growing businesses.',
    category: ProductCategory.productivity,
    status: ProductStatus.beta,
    accentHex: 0xFF7C3AED,
    productUrl: 'https://hris.costikstudio.com',
    adminUrl: 'https://admin.hris.costikstudio.com',
    features: [
      'Employee and department management',
      'Attendance, shifts, and leave workflow',
      'HR operation reports and approvals',
    ],
  ),
  ProductItem(
    id: 'smart-inv',
    name: 'Smart INV',
    tagline: 'Inventory control, stock movement, and item tracking system.',
    description: 'A smart inventory system for managing products, stock movements, item history, and operational inventory visibility.',
    category: ProductCategory.freeApp,
    status: ProductStatus.beta,
    accentHex: 0xFF10B981,
    productUrl: 'https://inventory.costikstudio.com',
    adminUrl: 'https://admin.inventory.costikstudio.com',
    downloadUrl: 'https://downloads.costikstudio.com/smart-inv/latest.apk',
    isFree: true,
    features: [
      'Product and stock movement tracking',
      'Inventory history and item visibility',
      'Low-stock and operational stock reports',
    ],
  ),
];

ProductItem? findProductById(String id) {
  for (final product in dummyProducts) {
    if (product.id == id) return product;
  }
  return null;
}

List<ProductItem> productsByCategory(ProductCategory category) {
  return dummyProducts
      .where((product) => product.category == category)
      .toList();
}

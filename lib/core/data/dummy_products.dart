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
    adminUrl: 'https://admin-ip-tv.pages.dev/',
    downloadUrl: 'https://drive.google.com/drive/folders/1i_pawAjDbQZeoLld_HGO40OfEIRypYSE?usp=drive_link',
    features: [
      'Live TV channel and video playlist management',
      'Room, device, and guest profile management',
      'Restaurant menu, category, and incoming order workflow',
      'Hotel information modules for facilities, dining, convention, maps, Wi-Fi, and about pages',
      'Guest request tools: service call, reviews, promo, and message/content menus',
      'App menu management for IPTV home shortcuts and digital services',
      'Company profile, about hotel, and in-room information pages',
      'ADB/device operations support for managed IPTV deployments',
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
    isNew: true,
    features: [
      'Digital Signage dengan tema Flight Board / FIDS terbaru',
      'Daily Event board dengan animasi arah (direction) dan status event real-time (Upcoming, Ongoing, Finished)',
      'Live Weather info dan Running Text per-device untuk pengumuman hotel',
      'Fullscreen video player dengan playlist dan overlay logo hotel',
      'TV/browser client pairing dengan 6-digit code dan manajemen kuota device',
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
    adminUrl: 'https://coshris.pages.dev',
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
  ProductItem(
    id: 'adb-manager',
    name: 'ADB Manager',
    tagline: 'Windows Desktop tool for managing Android TV devices via ADB.',
    description: 'Tools spesifik bagi teknisi instalasi untuk mempercepat proses eksekusi perintah ADB ke Android TV atau Set Top Box. Aplikasi ini berjalan murni di sistem operasi Windows.',
    category: ProductCategory.productivity,
    status: ProductStatus.beta,
    accentHex: 0xFFF97316,
    productUrl: 'https://costikstudio.com',
    downloadUrl: 'https://drive.google.com/drive/folders/153-9t8cYYZFX_aOfaVI52KRSjKk1mYOT?usp=drive_link',
    isFree: true,
    isNew: true,
    features: [
      'Instalasi aplikasi (APK) instan melalui jaringan atau kabel USB',
      'Manajemen DCO (Clear Cache, Set, Verify, Remove)',
      'Enable/Disable IPTV Launcher sebagai default launcher',
      'Hapus User atau Account sistem yang tidak terpakai dari TV',
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

import 'package:costikstudio/core/models/product_item.dart';

const dummyProducts = <ProductItem>[
  ProductItem(
    id: 'cospos',
    name: 'CosPOS Coffee Shop',
    tagline: 'Modern POS for coffee shops and F&B businesses.',
    description: 'A cloud-connected cashier, product, customer, discount, stock, and sales-report platform for coffee shops and small F&B teams.',
    category: ProductCategory.business,
    status: ProductStatus.live,
    accentHex: 0xFF7C3AED,
    productUrl: 'https://cospos.costikstudio.com',
    adminUrl: 'https://admin.cospos.costikstudio.com',
    features: [
      'Web admin and cashier dashboard',
      'Products, ingredients, discounts, customers, and outlets',
      'Sales, payment, debt, and stock reports',
      'Built-in Chat Support for mobile & web admin',
      'CosPOS store app_type login guard enforcement',
    ],
  ),
  ProductItem(
    id: 'cospos-kasir',
    name: 'CosPOS Kasir',
    tagline: 'Universal cashier app for stores and service businesses.',
    description: 'A general POS variant for cosmetics, kiosks, grocery, fashion, services, and other small businesses that need fast cashier operations.',
    category: ProductCategory.business,
    status: ProductStatus.beta,
    accentHex: 0xFF2563EB,
    productUrl: 'https://kasir.costikstudio.com',
    adminUrl: 'https://admin.kasir.costikstudio.com',
    features: [
      'Generic product and sales flow',
      'Multi-outlet and staff management',
      'Subscription-ready PRO features',
      'Universal POS branding (No coffee shop locked copy)',
    ],
  ),
  ProductItem(
    id: 'scoreboard-online',
    name: 'Scoreboard Online',
    tagline: 'Multi-sport digital scoreboard & realtime match timeline.',
    description: 'A mobile scoreboard for badminton, basketball, soccer, volleyball, and casual matches with realtime tracking, stats, frequency-capped AdMob monetization, and optional lifetime Remove Ads purchase.',
    category: ProductCategory.productivity,
    status: ProductStatus.live,
    accentHex: 0xFF10B981,
    productUrl: 'https://scoreboard.costikstudio.com',
    downloadUrl: 'https://apps.costikstudio.com/scoreboard-online',
    features: [
      'Multi-sport landscape scoreboard with tap to score',
      'Debounced realtime match persistence & Supabase stats',
      'Policy-safe AdMob setup (Frequency caps + Adaptive banners)',
      'Remove Ads Lifetime in-app purchase integration',
    ],
  ),
  ProductItem(
    id: 'costik-iptv',
    name: 'Costik IPTV',
    tagline: 'Hotel IPTV, live TV, and guest information system.',
    description: 'An IPTV platform for hotels and hospitality environments with local Live TV support, cloud content, and lightweight online/offline status.',
    category: ProductCategory.hospitality,
    status: ProductStatus.beta,
    accentHex: 0xFF0EA5E9,
    productUrl: 'https://iptv.costikstudio.com',
    adminUrl: 'https://admin.iptv.costikstudio.com',
    features: [
      'Live TV, digital/coaxial-ready guest flow',
      'Cloud menu and content management',
      'Non-blocking offline indicator for hotel devices',
    ],
  ),
  ProductItem(
    id: 'arisan-online',
    name: 'Arisan Online',
    tagline: 'Digital arisan groups, members, and draw management.',
    description: 'A mobile-first app for managing arisan groups, members, schedules, draws, and online collaboration.',
    category: ProductCategory.productivity,
    status: ProductStatus.live,
    accentHex: 0xFFEC4899,
    productUrl: 'https://arisan.costikstudio.com',
    downloadUrl: 'https://apps.costikstudio.com/arisan-online',
    features: [
      'Group and member management',
      'Online draw and history tracking',
      'Supabase-powered account sync',
    ],
  ),
  ProductItem(
    id: 'text-berjalan',
    name: 'LED Signboard',
    tagline: 'Create running text displays for global users.',
    description: 'A simple app for creating LED-style running text, signboard messages, and display-ready announcements.',
    category: ProductCategory.freeApp,
    status: ProductStatus.live,
    accentHex: 0xFFF97316,
    downloadUrl: 'https://apps.costikstudio.com/led-signboard',
    isFree: true,
    features: [
      'Running text preview',
      'Display-friendly signboard mode',
      'Simple global English UI',
    ],
  ),
  ProductItem(
    id: 'letter-tracing',
    name: 'Letter Tracing',
    tagline: 'A simple tracing app for early learning practice.',
    description: 'A learning app concept for children to practice letter tracing, stroke guidance, scoring, and progress rewards.',
    category: ProductCategory.freeApp,
    status: ProductStatus.beta,
    accentHex: 0xFF22C55E,
    downloadUrl: 'https://apps.costikstudio.com/letter-tracing',
    isFree: true,
    features: [
      'Letter stroke templates',
      'Practice scoring and feedback',
      'Rewards and progress tracking',
    ],
  ),
  ProductItem(
    id: 'rainsound',
    name: 'RainSound',
    tagline: 'Relaxing rain audio for focus, sleep, and calm moments.',
    description: 'A lightweight mobile app idea for calming rain sounds, ambience, focus, and simple relaxation sessions.',
    category: ProductCategory.freeApp,
    status: ProductStatus.comingSoon,
    accentHex: 0xFF14B8A6,
    downloadUrl: 'https://apps.costikstudio.com/rainsound',
    isFree: true,
    features: [
      'Mobile-only calming audio',
      'Focus and sleep ambience',
      'Simple offline-friendly listening',
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

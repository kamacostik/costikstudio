/// Shared per-device monthly pricing for wallet-billed products.
///
/// Keep these in sync with `docs/db/seed_*_product.sql`
/// (`products.price_per_device`). UI estimates, dummy repository math,
/// and subscription cards must all read from here.
/// IPTV starts at 50rb/device/month before volume discounts.
/// Signage remains 20rb/screen/month.
const int iptvPricePerDevice = 50000;
const int signagePricePerDevice = 20000;

/// IPTV video promo add-on: Rp50.000/month for 2 active videos.
const int iptvVideoAddonPrice = 50000;
const Map<String, dynamic> iptvVideoAddonMediaLimits = {
  'media_storage_limit_mb': 2000,
  'image_upload_enabled': true,
  'video_upload_enabled': true,
  'video_max_file_size_mb': 100,
  'video_max_duration_seconds': 120,
  'video_active_limit': 2,
};

int unitPriceForProductId(String productId) {
  if (productId == 'costik-signage') return signagePricePerDevice;
  return iptvPricePerDevice;
}

String shortNameForProductId(String productId) {
  if (productId == 'costik-signage') return 'Signage';
  if (productId == 'costik-iptv') return 'IPTV';
  return productId;
}

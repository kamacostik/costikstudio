/// Shared per-device monthly pricing for wallet-billed products.
///
/// Keep these in sync with `docs/db/seed_*_product.sql`
/// (`products.price_per_device`). UI estimates, dummy repository math,
/// and subscription cards must all read from here. Both wallet-billed
/// products (IPTV + Signage) are 20rb/device/month.
const int iptvPricePerDevice = 20000;
const int signagePricePerDevice = 20000;

int unitPriceForProductId(String productId) {
  if (productId == 'costik-signage') return signagePricePerDevice;
  return iptvPricePerDevice;
}

String shortNameForProductId(String productId) {
  if (productId == 'costik-signage') return 'Signage';
  if (productId == 'costik-iptv') return 'IPTV';
  return productId;
}

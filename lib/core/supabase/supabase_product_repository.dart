import 'package:costikstudio/core/models/product_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProductRepository {
  const SupabaseProductRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Future<List<ProductItem>> fetchProducts() async {
    final rows = await _supabase
        .from('products')
        .select('id, name, tagline, price_per_device')
        .order('name');

    return rows.map<ProductItem>((row) {
      final id = row['id'] as String;
      final name = row['name'] as String;
      final tagline = row['tagline'] as String? ?? '';
      final isSignage = id == 'costik-signage' || id == 'digital-signage';
      return ProductItem(
        id: id,
        name: name,
        tagline: tagline,
        description: isSignage
            ? 'A subscription-based digital signage platform for hotels and public screens. Manage hotel profile/logo, Daily Event schedules, media library, multi-video playlists, device pairing, and per-device display mode from CostikStudio Web Admin.'
            : tagline,
        category: isSignage
            ? ProductCategory.business
            : ProductCategory.hospitality,
        status: ProductStatus.live,
        accentHex: isSignage ? 0xFF2563EB : 0xFF0EA5E9,
        features: isSignage
            ? const [
                'Daily Event board with date, start/end time, room, floor, auto-slide, and manual OK refresh',
                'Fullscreen video player with hotel logo overlay and multi-video playlist order',
                'TV/browser client pairing with 6-digit code, device quota, online status, and per-device mode',
              ]
            : const [
                'Device licence tracking',
                'Subscription-ready IPTV product',
              ],
      );
    }).toList();
  }
}

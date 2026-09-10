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
      return ProductItem(
        id: id,
        name: name,
        tagline: tagline,
        description: tagline,
        category: ProductCategory.hospitality,
        status: ProductStatus.live,
        accentHex: 0xFF2563EB,
        features: const [
          'Device licence tracking',
          'Subscription-ready IPTV product',
        ],
      );
    }).toList();
  }
}

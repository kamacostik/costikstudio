import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'IPTV pricing discount schema defines volume tiers and launch vouchers',
    () {
      final sql = File('docs/db/iptv_pricing_discounts.sql').readAsStringSync();

      expect(
        sql,
        contains('create table if not exists public.product_volume_discounts'),
      );
      expect(sql, contains('create table if not exists public.promo_codes'));
      expect(
        sql,
        contains('create table if not exists public.promo_redemptions'),
      );
      expect(sql, contains('price_per_device = 50000'));
      expect(sql, contains("('costik-iptv', 10, 10"));
      expect(sql, contains("('costik-iptv', 50, 30"));
      expect(sql, contains("('costik-iptv', 100, 60"));
      expect(sql, contains("'WELCOME20'"));
      expect(sql, contains("'LAUNCH30'"));
      expect(sql, contains('new_customer_only boolean not null default true'));
      expect(sql, contains('promo_redemptions_user_code_idx'));
    },
  );
}

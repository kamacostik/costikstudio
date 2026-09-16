import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'IPTV checkout RPC calculates volume and voucher discounts server side',
    () {
      final sql = File('docs/db/iptv_subscription_rpc.sql').readAsStringSync();

      expect(sql, contains('p_voucher_code text default null'));
      expect(sql, contains('public.product_volume_discounts'));
      expect(sql, contains('volume_discount_percent'));
      expect(sql, contains('voucher_discount_percent'));
      expect(sql, contains('public.promo_codes'));
      expect(sql, contains('public.promo_redemptions'));
      expect(sql, contains('new_customer_only'));
      expect(
        sql,
        contains(
          'total_amount := subtotal_after_volume - voucher_discount_amount + addon_total',
        ),
      );
      expect(sql, contains('insert into public.promo_redemptions'));
    },
  );
}

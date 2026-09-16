import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('IPTV upgrade RPC blocks expired subscriptions server-side', () {
    final sql = File('docs/db/iptv_subscription_upgrade_device_rpc.sql')
        .readAsStringSync();

    expect(sql, contains("and expires_at > now()"));
    expect(sql, contains('Only active IPTV subscriptions can be upgraded'));
  });

  test(
    'database has maintenance helper to mark elapsed subscriptions expired',
    () {
      final sql = File('docs/db/subscription_expiry.sql').readAsStringSync();

      expect(sql, contains('mark_expired_subscriptions'));
      expect(sql, contains("status = 'expired'"));
      expect(sql, contains('expires_at <= now()'));
    },
  );
}

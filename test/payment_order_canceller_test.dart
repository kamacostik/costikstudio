import 'package:costikstudio/core/payment/payment_order_canceller.dart';
import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() => SupabaseConfig.load(const {}));

  test('does nothing when Supabase url is missing', () async {
    SupabaseConfig.load(const {});

    final cancelled = await const PaymentOrderCanceller()
        .cancelByExternalReference('TOPUP-001');

    expect(cancelled, isFalse);
  });

  test('calls cancel pending top up order RPC', () async {
    SupabaseConfig.load({
      'SUPABASE_URL': 'https://project.supabase.co',
      'SUPABASE_ANON_KEY': 'anon-key',
    });

    final canceller = PaymentOrderCanceller(
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://project.supabase.co/rest/v1/rpc/cancel_pending_topup_order',
        );
        expect(request.headers['apikey'], 'anon-key');
        expect(request.headers['Authorization'], 'Bearer anon-key');
        expect(request.body, '{"target_external_reference":"TOPUP-001"}');
        return http.Response('{"status":"cancelled"}', 200);
      }),
    );

    final cancelled = await canceller.cancelByExternalReference('TOPUP-001');

    expect(cancelled, isTrue);
  });
}

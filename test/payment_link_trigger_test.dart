import 'dart:convert';

import 'package:costikstudio/core/billing/topup_order_result.dart';
import 'package:costikstudio/core/payment/payment_link_trigger.dart';
import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  tearDown(() => SupabaseConfig.load(const {}));

  test('does nothing when create payment webhook url is missing', () async {
    var called = false;
    final trigger = PaymentLinkTrigger(
      client: MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );

    final result = await trigger.triggerTopUpOrder(_order());

    expect(result, isNull);
    expect(called, isFalse);
  });

  test('posts top up order and returns payment data from webhook', () async {
    SupabaseConfig.load(const {
      'SUMOPOD_CREATE_PAYMENT_WEBHOOK_URL':
          'https://n8n.example.com/webhook/costikstudio-sumopod-create-payment',
    });

    late http.Request capturedRequest;
    final trigger = PaymentLinkTrigger(
      client: MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'ok': true,
            'payment_url': 'https://pay.example.com/pay/order-123',
            'payment_code': 'qr-text',
            'payment_code_type': 'QR_TEXT',
            'payment_channel_used': 'QRIS',
          }),
          200,
        );
      }),
    );

    final result = await trigger.triggerTopUpOrder(_order());

    expect(result?.paymentLinkRequested, isTrue);
    expect(result?.paymentUrl, 'https://pay.example.com/pay/order-123');
    expect(result?.paymentCode, 'qr-text');
    expect(result?.paymentCodeType, 'QR_TEXT');
    expect(result?.paymentChannelUsed, 'QRIS');
    expect(
      capturedRequest.url.toString(),
      'https://n8n.example.com/webhook/costikstudio-sumopod-create-payment',
    );
    expect(capturedRequest.headers['Content-Type'], 'application/json');

    final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
    expect(body['order_id'], 'TOPUP-123');
    expect(body['amount'], 100000);
    expect(body['payment_method_type_code'], 'QRIS');
    expect(body['source'], 'costikstudio_flutter');
  });

  test('returns null when create payment webhook fails', () async {
    SupabaseConfig.load(const {
      'SUMOPOD_CREATE_PAYMENT_WEBHOOK_URL':
          'https://n8n.example.com/webhook/costikstudio-sumopod-create-payment',
    });

    final trigger = PaymentLinkTrigger(
      client: MockClient((request) async => http.Response('failed', 500)),
    );

    final result = await trigger.triggerTopUpOrder(_order());

    expect(result, isNull);
  });
}

TopUpOrderResult _order() {
  return const TopUpOrderResult(
    orderId: 'order-123',
    externalReference: 'TOPUP-123',
    status: 'pending',
    amount: 100000,
  );
}

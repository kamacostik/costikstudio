import 'dart:convert';

import 'package:costikstudio/core/billing/topup_order_result.dart';
import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:http/http.dart' as http;

class PaymentLinkTrigger {
  const PaymentLinkTrigger({this.client});

  final http.Client? client;

  bool get isConfigured =>
      SupabaseConfig.sumopodCreatePaymentWebhookUrl.isNotEmpty;

  Future<TopUpOrderResult?> triggerTopUpOrder(TopUpOrderResult order) async {
    final webhookUrl = SupabaseConfig.sumopodCreatePaymentWebhookUrl;
    if (webhookUrl.isEmpty) return null;

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final response = await httpClient.post(
        Uri.parse(webhookUrl),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': order.externalReference,
          'amount': order.amount,
          'payment_method_type_code': 'QRIS',
          'source': 'costikstudio_flutter',
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final paymentUrl = body['payment_url'] as String?;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        return order.copyWith(paymentLinkRequested: true);
      }

      return order.copyWith(
        paymentUrl: paymentUrl,
        paymentCode: body['payment_code'] as String?,
        paymentCodeType: body['payment_code_type'] as String?,
        paymentChannelUsed: body['payment_channel_used'] as String?,
        paymentLinkRequested: true,
      );
    } on FormatException {
      return order.copyWith(paymentLinkRequested: true);
    } finally {
      if (shouldCloseClient) httpClient.close();
    }
  }
}

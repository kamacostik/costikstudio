import 'dart:async';
import 'dart:convert';

import 'package:costikstudio/core/billing/topup_order_result.dart';
import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:http/http.dart' as http;

class PaymentLinkTrigger {
  const PaymentLinkTrigger({this.client});

  static const _customerPaymentLinkError = 'Gagal membuat link pembayaran.';

  final http.Client? client;

  bool get isConfigured =>
      SupabaseConfig.sumopodCreatePaymentWebhookUrl.isNotEmpty;

  Future<TopUpOrderResult?> triggerTopUpOrder(TopUpOrderResult order) async {
    final webhookUrl = SupabaseConfig.sumopodCreatePaymentWebhookUrl;
    if (webhookUrl.isEmpty) return null;

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final response = await httpClient
          .post(
            Uri.parse(webhookUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'order_id': order.externalReference,
              'amount': order.amount,
              'payment_method_type_code': 'QRIS',
              'source': 'costikstudio_flutter',
            }),
          )
          .timeout(const Duration(seconds: 25));

      final responseBody = _decodeResponse(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return order.copyWith(
          paymentErrorMessage: _customerPaymentLinkError,
          paymentLinkRequested: true,
        );
      }

      final paymentUrl = responseBody['payment_url'] as String?;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        return order.copyWith(
          paymentErrorMessage: _customerPaymentLinkError,
          paymentLinkRequested: true,
        );
      }

      return order.copyWith(
        paymentUrl: paymentUrl,
        paymentCode: responseBody['payment_code'] as String?,
        paymentCodeType: responseBody['payment_code_type'] as String?,
        paymentChannelUsed: responseBody['payment_channel_used'] as String?,
        paymentLinkRequested: true,
      );
    } on TimeoutException {
      return order.copyWith(
        paymentErrorMessage: _customerPaymentLinkError,
        paymentLinkRequested: true,
      );
    } on FormatException {
      return order.copyWith(
        paymentErrorMessage: _customerPaymentLinkError,
        paymentLinkRequested: true,
      );
    } catch (_) {
      return order.copyWith(
        paymentErrorMessage: _customerPaymentLinkError,
        paymentLinkRequested: true,
      );
    } finally {
      if (shouldCloseClient) httpClient.close();
    }
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.trim().isEmpty) return const {};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }
}

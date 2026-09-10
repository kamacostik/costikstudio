import 'dart:async';
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
          paymentErrorMessage:
              _errorMessage(responseBody) ??
              'Gagal membuat link pembayaran dari n8n (${response.statusCode}).',
          paymentLinkRequested: true,
        );
      }

      final paymentUrl = responseBody['payment_url'] as String?;
      if (paymentUrl == null || paymentUrl.isEmpty) {
        return order.copyWith(
          paymentErrorMessage:
              _errorMessage(responseBody) ??
              'n8n belum mengembalikan link pembayaran.',
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
        paymentErrorMessage: 'n8n terlalu lama merespon. Coba buat link baru atau batalkan transaksi.',
        paymentLinkRequested: true,
      );
    } on FormatException {
      return order.copyWith(
        paymentErrorMessage: 'Response n8n tidak valid.',
        paymentLinkRequested: true,
      );
    } catch (_) {
      return order.copyWith(
        paymentErrorMessage:
            'Gagal menghubungi n8n. Periksa workflow create payment.',
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

  String? _errorMessage(Map<String, dynamic> body) {
    for (final key in [
      'message',
      'error',
      'errorMessage',
      'error_description',
    ]) {
      final value = body[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}

import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:http/http.dart' as http;

class PaymentOrderCanceller {
  const PaymentOrderCanceller({this.client});

  final http.Client? client;

  Future<bool> cancelByExternalReference(String externalReference) async {
    if (externalReference.trim().isEmpty || SupabaseConfig.url.isEmpty) {
      return false;
    }

    final requestClient = client ?? http.Client();
    try {
      final response = await requestClient.post(
        Uri.parse(
          '${SupabaseConfig.url}/rest/v1/rpc/cancel_pending_topup_order',
        ),
        headers: {
          'Content-Type': 'application/json',
          'apikey': SupabaseConfig.anonKey,
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
        },
        body: '{"target_external_reference":"$externalReference"}',
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    } finally {
      if (client == null) requestClient.close();
    }
  }
}

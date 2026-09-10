import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentOrderCanceller {
  const PaymentOrderCanceller({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  Future<bool> cancelByExternalReference(String externalReference) async {
    if (externalReference.trim().isEmpty) return false;

    try {
      await _supabase.rpc<void>(
        'cancel_pending_topup_order',
        params: {'target_external_reference': externalReference},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

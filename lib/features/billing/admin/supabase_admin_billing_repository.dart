import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:costikstudio/features/billing/admin/admin_billing_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAdminBillingRepository implements AdminBillingRepository {
  const SupabaseAdminBillingRepository();

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<AdminBillingSnapshot> loadSnapshot() async {
    final response = await _supabase.rpc<Map<String, dynamic>>(
      'admin_get_billing_overview',
    );

    final rawTopUps = response['pendingTopUps'] as List<dynamic>? ?? [];
    final rawWallets = response['customerWallets'] as List<dynamic>? ?? [];
    final rawSubs = response['allSubscriptions'] as List<dynamic>? ?? [];

    final pendingTopUps = rawTopUps.map((e) {
      final map = e as Map<String, dynamic>;
      final status = map['status'] as String? ?? 'pending';
      return PendingTopUp(
        id: map['id'] as String,
        customerName: map['customer_name'] as String? ?? '',
        amount: (map['amount'] as num?)?.toInt() ?? 0,
        method: '${map['method']} ($status)',
      );
    }).toList();

    final customerWallets = rawWallets.map((e) {
      final map = e as Map<String, dynamic>;
      final balance = (map['balance'] as num?)?.toInt() ?? 0;
      return CustomerWalletSummary(
        customerName: map['customer_name'] as String? ?? '',
        statusText: 'Saldo: Rp $balance',
      );
    }).toList();

    final allSubscriptions = rawSubs.map((e) {
      final map = e as Map<String, dynamic>;
      return AdminSubscriptionRecord(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        customerEmail: map['customer_email'] as String? ?? '',
        productName: map['product_name'] as String? ?? '',
        deviceCount: (map['device_count'] as num?)?.toInt() ?? 0,
        billingCycleMonths: (map['billing_cycle_months'] as num?)?.toInt() ?? 1,
        statusText: map['status_text'] as String? ?? '',
        startedAt: DateTime.parse(map['started_at'] as String).toLocal(),
        expiresAt: DateTime.parse(map['expires_at'] as String).toLocal(),
      );
    }).toList();

    return AdminBillingSnapshot(
      pendingTopUps: pendingTopUps,
      customerWallets: customerWallets,
      subscriptionMetrics: [
        SubscriptionMetric(
          label: 'Total Customers',
          value: '${allSubscriptions.length}',
        ),
        SubscriptionMetric(
          label: 'Total Devices',
          value:
              '${allSubscriptions.fold<int>(0, (sum, item) => sum + item.deviceCount)}',
        ),
        SubscriptionMetric(
          label: 'Active Sub',
          value:
              '${allSubscriptions.where((s) => s.statusText == 'active').length}',
        ),
      ],
      allSubscriptions: allSubscriptions,
      revenueToday: (response['revenueToday'] as num?)?.toDouble() ?? 0,
      revenueMonth: (response['revenueMonth'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Future<AdminBillingSnapshot> approveTopUp(String topUpId) async {
    // Top ups should be approved via n8n/sumopod webhook or direct DB manipulation.
    // For now we just reload.
    return loadSnapshot();
  }

  @override
  Future<AdminBillingSnapshot> adminExtendSubscription({
    required String subscriptionId,
    required int additionalMonths,
  }) async {
    await _supabase.rpc<void>(
      'admin_extend_iptv_subscription',
      params: {
        'target_subscription_id': subscriptionId,
        'additional_months': additionalMonths,
      },
    );
    return loadSnapshot();
  }

  @override
  Future<AdminBillingSnapshot> adminUpdateDevices({
    required String subscriptionId,
    required int newDeviceCount,
  }) async {
    await _supabase.rpc<void>(
      'admin_update_iptv_device_count',
      params: {
        'target_subscription_id': subscriptionId,
        'new_device_count': newDeviceCount,
      },
    );
    return loadSnapshot();
  }
}

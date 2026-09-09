import 'package:costikstudio/features/billing/admin/admin_billing_repository.dart';

class DummyAdminBillingRepository implements AdminBillingRepository {
  DummyAdminBillingRepository()
    : _pendingTopUps = [
        const PendingTopUp(
          id: 'topup-kendari-hotel',
          customerName: 'Kendari Hotel Group',
          amount: 250000,
          method: 'Manual transfer',
        ),
      ];

  final List<PendingTopUp> _pendingTopUps;

  @override
  Future<AdminBillingSnapshot> loadSnapshot() async => _snapshot();

  @override
  Future<AdminBillingSnapshot> approveTopUp(String topUpId) async {
    final topUp = _pendingTopUps
        .where((item) => item.id == topUpId)
        .firstOrNull;
    if (topUp == null) return _snapshot();

    _pendingTopUps.removeWhere((item) => item.id == topUpId);
    return _snapshot(message: 'Top up ${topUp.customerName} disetujui');
  }

  AdminBillingSnapshot _snapshot({String? message}) {
    return AdminBillingSnapshot(
      pendingTopUps: List.unmodifiable(_pendingTopUps),
      customerWallets: const [
        CustomerWalletSummary(
          customerName: 'Kendari Hotel Group',
          statusText: 'Rp 250.000 pending',
        ),
        CustomerWalletSummary(
          customerName: 'Demo Customer',
          statusText: 'Rp 350.000 active',
        ),
      ],
      subscriptionMetrics: const [
        SubscriptionMetric(label: 'Active subscriptions', value: '2'),
        SubscriptionMetric(label: 'Manual renew accounts', value: '1'),
        SubscriptionMetric(label: 'Auto renew accounts', value: '1'),
      ],
      message: message,
    );
  }
}

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
      ],
      _allSubscriptions = [
        AdminSubscriptionRecord(
          id: 'sub-kendari-01',
          userId: 'user-kendari',
          customerEmail: 'admin@kendarihotel.com',
          productName: 'Costik IPTV',
          deviceCount: 25,
          billingCycleMonths: 1,
          statusText: 'active',
          startedAt: DateTime(2026, 9, 1),
          expiresAt: DateTime(2026, 10, 1),
        ),
        AdminSubscriptionRecord(
          id: 'sub-demo-iptv',
          userId: 'demo-user',
          customerEmail: 'user@costik.com',
          productName: 'Costik IPTV',
          deviceCount: 5,
          billingCycleMonths: 1,
          statusText: 'active',
          startedAt: DateTime(2026, 9, 5),
          expiresAt: DateTime(2026, 10, 5),
        ),
      ];

  final List<PendingTopUp> _pendingTopUps;
  final List<AdminSubscriptionRecord> _allSubscriptions;

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

  @override
  Future<AdminBillingSnapshot> adminExtendSubscription({
    required String subscriptionId,
    required int additionalMonths,
  }) async {
    final index = _allSubscriptions.indexWhere(
      (sub) => sub.id == subscriptionId,
    );
    if (index == -1) return _snapshot();

    final current = _allSubscriptions[index];
    _allSubscriptions[index] = AdminSubscriptionRecord(
      id: current.id,
      userId: current.userId,
      customerEmail: current.customerEmail,
      productName: current.productName,
      deviceCount: current.deviceCount,
      billingCycleMonths: current.billingCycleMonths,
      statusText: current.statusText,
      startedAt: current.startedAt,
      expiresAt: current.expiresAt.add(Duration(days: 30 * additionalMonths)),
    );

    return _snapshot(
      message:
          'Subscription ${current.customerEmail} diperpanjang $additionalMonths bulan (Admin Action).',
    );
  }

  @override
  Future<AdminBillingSnapshot> adminUpdateDevices({
    required String subscriptionId,
    required int newDeviceCount,
  }) async {
    final index = _allSubscriptions.indexWhere(
      (sub) => sub.id == subscriptionId,
    );
    if (index == -1) return _snapshot();

    final current = _allSubscriptions[index];
    _allSubscriptions[index] = AdminSubscriptionRecord(
      id: current.id,
      userId: current.userId,
      customerEmail: current.customerEmail,
      productName: current.productName,
      deviceCount: newDeviceCount,
      billingCycleMonths: current.billingCycleMonths,
      statusText: current.statusText,
      startedAt: current.startedAt,
      expiresAt: current.expiresAt,
    );

    return _snapshot(
      message:
          'Jumlah device ${current.customerEmail} diubah menjadi $newDeviceCount (Admin Action).',
    );
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
      subscriptionMetrics: [
        SubscriptionMetric(
          label: 'Total Customers',
          value: '${_allSubscriptions.length}',
        ),
        SubscriptionMetric(
          label: 'Total Devices Monitored',
          value:
              '${_allSubscriptions.fold<int>(0, (sum, item) => sum + item.deviceCount)}',
        ),
        SubscriptionMetric(
          label: 'Active Subscriptions',
          value:
              '${_allSubscriptions.where((s) => s.statusText == 'active').length}',
        ),
      ],
      allSubscriptions: List.unmodifiable(_allSubscriptions),
      message: message,
    );
  }
}

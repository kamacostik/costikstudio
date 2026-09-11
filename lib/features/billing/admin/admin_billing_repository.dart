class PendingTopUp {
  const PendingTopUp({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.method,
  });

  final String id;
  final String customerName;
  final int amount;
  final String method;
}

class CustomerWalletSummary {
  const CustomerWalletSummary({
    required this.customerName,
    required this.statusText,
  });

  final String customerName;
  final String statusText;
}

class SubscriptionMetric {
  const SubscriptionMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class AdminSubscriptionRecord {
  const AdminSubscriptionRecord({
    required this.id,
    required this.userId,
    required this.customerEmail,
    required this.productName,
    required this.deviceCount,
    required this.billingCycleMonths,
    required this.statusText,
    required this.startedAt,
    required this.expiresAt,
  });

  final String id;
  final String userId;
  final String customerEmail;
  final String productName;
  final int deviceCount;
  final int billingCycleMonths;
  final String statusText;
  final DateTime startedAt;
  final DateTime expiresAt;
}

class AdminBillingSnapshot {
  const AdminBillingSnapshot({
    required this.pendingTopUps,
    required this.customerWallets,
    required this.subscriptionMetrics,
    this.allSubscriptions = const [],
    this.message,
  });

  final List<PendingTopUp> pendingTopUps;
  final List<CustomerWalletSummary> customerWallets;
  final List<SubscriptionMetric> subscriptionMetrics;
  final List<AdminSubscriptionRecord> allSubscriptions;
  final String? message;
}

abstract class AdminBillingRepository {
  Future<AdminBillingSnapshot> loadSnapshot();

  Future<AdminBillingSnapshot> approveTopUp(String topUpId);

  Future<AdminBillingSnapshot> adminExtendSubscription({
    required String subscriptionId,
    required int additionalMonths,
  });

  Future<AdminBillingSnapshot> adminUpdateDevices({
    required String subscriptionId,
    required int newDeviceCount,
  });
}

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

class AdminBillingSnapshot {
  const AdminBillingSnapshot({
    required this.pendingTopUps,
    required this.customerWallets,
    required this.subscriptionMetrics,
    this.message,
  });

  final List<PendingTopUp> pendingTopUps;
  final List<CustomerWalletSummary> customerWallets;
  final List<SubscriptionMetric> subscriptionMetrics;
  final String? message;
}

abstract class AdminBillingRepository {
  Future<AdminBillingSnapshot> loadSnapshot();

  Future<AdminBillingSnapshot> approveTopUp(String topUpId);
}

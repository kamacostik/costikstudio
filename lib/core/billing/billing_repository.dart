import 'package:costikstudio/core/billing/billing_core.dart';

class BillingSnapshot {
  const BillingSnapshot({
    required this.wallet,
    required this.products,
    required this.plans,
    required this.subscriptions,
    required this.transactions,
    required this.invoices,
    this.message,
  });

  final Wallet wallet;
  final List<BillingProduct> products;
  final List<BillingPlan> plans;
  final List<Subscription> subscriptions;
  final List<WalletTransaction> transactions;
  final List<BillingInvoice> invoices;
  final String? message;
}

abstract class BillingRepository {
  Future<BillingSnapshot> loadSnapshot();

  Future<BillingSnapshot> topUp({required int amount});

  Future<BillingSnapshot> checkoutPlan({required String planId});
}

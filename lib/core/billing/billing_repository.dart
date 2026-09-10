import 'package:costikstudio/core/billing/billing_core.dart';

class BillingSnapshot {
  const BillingSnapshot({
    required this.wallet,
    required this.products,
    required this.plans,
    required this.subscriptions,
    required this.transactions,
    required this.invoices,
    this.paymentOrders = const [],
    this.message,
  });

  final Wallet wallet;
  final List<BillingProduct> products;
  final List<BillingPlan> plans;
  final List<Subscription> subscriptions;
  final List<WalletTransaction> transactions;
  final List<BillingInvoice> invoices;
  final List<PaymentOrder> paymentOrders;
  final String? message;
}

class PaymentOrder {
  const PaymentOrder({
    required this.id,
    required this.externalReference,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paymentUrl,
  });

  final String id;
  final String externalReference;
  final int amount;
  final String status;
  final DateTime createdAt;
  final String? paymentUrl;

  bool get isPending => status == 'pending';
}

abstract class BillingRepository {
  Future<BillingSnapshot> loadSnapshot();

  Future<BillingSnapshot> topUp({required int amount});

  Future<BillingSnapshot> checkoutPlan({required String planId});

  Future<BillingSnapshot> checkoutIptvSubscription({
    required int deviceCount,
    required int billingCycleMonths,
  });
}

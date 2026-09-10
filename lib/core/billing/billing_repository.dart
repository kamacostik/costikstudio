import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/topup_order_result.dart';

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
    this.provider = 'manual',
    this.currency = 'IDR',
    this.paymentMethodTypeCode,
    this.expiresAt,
  });

  final String id;
  final String externalReference;
  final int amount;
  final String status;
  final DateTime createdAt;
  final String? paymentUrl;
  final String provider;
  final String currency;
  final String? paymentMethodTypeCode;
  final DateTime? expiresAt;

  bool get isPending => status == 'pending';
  bool get hasPaymentUrl => paymentUrl != null && paymentUrl!.isNotEmpty;
}

abstract class BillingRepository {
  Future<BillingSnapshot> loadSnapshot();

  Future<TopUpOrderResult?> topUp({required int amount});

  Future<BillingSnapshot> checkoutPlan({required String planId});

  Future<BillingSnapshot> checkoutIptvSubscription({
    required int deviceCount,
    required int billingCycleMonths,
  });
}

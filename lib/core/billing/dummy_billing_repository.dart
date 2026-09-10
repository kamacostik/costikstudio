import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/billing/dummy_billing_data.dart';

class DummyBillingRepository implements BillingRepository {
  DummyBillingRepository()
    : _wallet = const Wallet(userId: 'demo-user', balance: 350000),
      _subscriptions = List.of(dummySubscriptions),
      _transactions = [
        const WalletTransaction(
          userId: 'demo-user',
          type: WalletTransactionType.purchase,
          amount: 150000,
          balanceBefore: 500000,
          balanceAfter: 350000,
          referenceId: 'checkout:costik-signage:signage-pro',
        ),
      ],
      _invoices = [
        BillingInvoice.fromWalletTransaction(
          transaction: const WalletTransaction(
            userId: 'demo-user',
            type: WalletTransactionType.purchase,
            amount: 150000,
            balanceBefore: 500000,
            balanceAfter: 350000,
            referenceId: 'checkout:costik-signage:signage-pro',
          ),
          number: 'INV-20260909-001',
          issuedAt: DateTime(2026, 9, 9),
        ),
      ];

  Wallet _wallet;
  final List<Subscription> _subscriptions;
  final List<WalletTransaction> _transactions;
  final List<BillingInvoice> _invoices;

  @override
  Future<BillingSnapshot> loadSnapshot() async => _snapshot();

  @override
  Future<BillingSnapshot> topUp({required int amount}) async {
    final result = _wallet.applyTopUp(
      amount: amount,
      referenceId: 'dummy-topup-$amount',
    );
    _wallet = result.wallet;
    _transactions.insert(0, result.transaction);
    _invoices.insert(0, _invoiceFrom(result.transaction));
    return _snapshot(message: 'Dummy top up berhasil');
  }

  @override
  Future<BillingSnapshot> checkoutPlan({required String planId}) async {
    final plan = dummyBillingPlanById(planId);
    if (plan == null) {
      throw ArgumentError.value(planId, 'planId', 'Unknown billing plan.');
    }
    return _checkout(plan: plan);
  }

  @override
  Future<BillingSnapshot> checkoutIptvSubscription({
    required int deviceCount,
    required int billingCycleMonths,
  }) async {
    final amount = deviceCount * 20000 * billingCycleMonths;
    final plan = BillingPlan(
      id: 'costik-iptv:custom',
      productId: 'costik-iptv',
      name: '$deviceCount Device / $billingCycleMonths Bulan',
      price: amount,
      durationDays: 30 * billingCycleMonths,
      features: const ['Custom IPTV device licence'],
    );
    return _checkout(plan: plan);
  }

  Future<BillingSnapshot> _checkout({required BillingPlan plan}) async {
    final product = dummyBillingProductById(plan.productId);
    if (product == null) {
      throw ArgumentError.value(
        plan.productId,
        'productId',
        'Unknown product.',
      );
    }

    try {
      final existingSubscription = _subscriptions
          .where((subscription) => subscription.productId == product.id)
          .firstOrNull;
      final result = BillingCheckout.checkoutPlan(
        wallet: _wallet,
        product: product,
        plan: plan,
        existingSubscription: existingSubscription,
        now: DateTime(2026, 9, 9),
      );

      _wallet = result.wallet;
      _transactions.insert(0, result.transaction);
      _invoices.insert(0, _invoiceFrom(result.transaction));
      _subscriptions.removeWhere(
        (subscription) =>
            subscription.productId == result.subscription.productId,
      );
      _subscriptions.insert(0, result.subscription);
      return _snapshot(message: '${product.name} ${plan.name} aktif');
    } on InsufficientBalanceException catch (error) {
      return _snapshot(
        message: 'Saldo kurang ${formatRupiah(error.shortfall)}',
      );
    }
  }

  BillingInvoice _invoiceFrom(WalletTransaction transaction) {
    return BillingInvoice.fromWalletTransaction(
      transaction: transaction,
      number:
          'INV-20260909-${(_invoices.length + 1).toString().padLeft(3, '0')}',
      issuedAt: DateTime(2026, 9, 9),
    );
  }

  BillingSnapshot _snapshot({String? message}) {
    return BillingSnapshot(
      wallet: _wallet,
      products: List.unmodifiable(dummyBillingProducts),
      plans: List.unmodifiable(dummyBillingPlans),
      subscriptions: List.unmodifiable(_subscriptions),
      transactions: List.unmodifiable(_transactions),
      invoices: List.unmodifiable(_invoices),
      paymentOrders: const [],
      message: message,
    );
  }
}

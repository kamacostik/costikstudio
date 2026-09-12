import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/billing/billing_pricing.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/billing/topup_order_result.dart';
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
  Future<TopUpOrderResult?> topUp({
    required int amount,
    bool requestPaymentLink = true,
  }) async {
    final result = _wallet.applyTopUp(
      amount: amount,
      referenceId: 'dummy-topup-$amount',
    );
    _wallet = result.wallet;
    _transactions.insert(0, result.transaction);
    _invoices.insert(0, _invoiceFrom(result.transaction));
    return TopUpOrderResult(
      orderId: 'dummy-topup-$amount',
      externalReference: 'dummy-topup-$amount',
      status: 'paid',
      amount: amount,
    );
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
    bool autoRenew = false,
  }) async {
    final amount = deviceCount * iptvPricePerDevice * billingCycleMonths;
    final plan = BillingPlan(
      id: 'costik-iptv:custom',
      productId: 'costik-iptv',
      name: '$deviceCount Device / $billingCycleMonths Bulan',
      price: amount,
      durationDays: 30 * billingCycleMonths,
      features: const ['Custom IPTV device licence'],
    );
    return _checkout(plan: plan, autoRenew: autoRenew);
  }

  @override
  Future<BillingSnapshot> checkoutSignageSubscription({
    required int deviceCount,
    required int billingCycleMonths,
    bool autoRenew = false,
  }) async {
    final amount = deviceCount * signagePricePerDevice * billingCycleMonths;
    final plan = BillingPlan(
      id: 'costik-signage:custom',
      productId: 'costik-signage',
      name: '$deviceCount Screen / $billingCycleMonths Bulan',
      price: amount,
      durationDays: 30 * billingCycleMonths,
      features: const ['Custom Signage screen licence'],
    );
    return _checkout(plan: plan, autoRenew: autoRenew);
  }

  @override
  Future<BillingSnapshot> renewIptvSubscription({
    required String subscriptionId,
    required int billingCycleMonths,
  }) async {
    return _renewSubscription(
      subscriptionId: subscriptionId,
      billingCycleMonths: billingCycleMonths,
      productId: 'costik-iptv',
    );
  }

  @override
  Future<BillingSnapshot> renewSignageSubscription({
    required String subscriptionId,
    required int billingCycleMonths,
  }) async {
    return _renewSubscription(
      subscriptionId: subscriptionId,
      billingCycleMonths: billingCycleMonths,
      productId: 'costik-signage',
    );
  }

  Future<BillingSnapshot> _renewSubscription({
    required String subscriptionId,
    required int billingCycleMonths,
    required String productId,
  }) async {
    if (billingCycleMonths <= 0) {
      throw ArgumentError.value(
        billingCycleMonths,
        'billingCycleMonths',
        'Billing cycle must be greater than zero.',
      );
    }

    final index = _subscriptions.indexWhere(
      (subscription) => subscription.id == subscriptionId,
    );
    if (index == -1) {
      throw ArgumentError.value(
        subscriptionId,
        'subscriptionId',
        'Unknown subscription.',
      );
    }

    final subscription = _subscriptions[index];
    final product = dummyBillingProductById(subscription.productId);
    if (product == null || product.id != productId) {
      throw ArgumentError.value(
        subscription.productId,
        'productId',
        'Only $productId subscription renewal is supported.',
      );
    }

    final unitPrice = unitPriceForProductId(product.id);
    final amount = subscription.deviceCount * unitPrice * billingCycleMonths;
    if (_wallet.balance < amount) {
      return _snapshot(
        message: 'Saldo kurang ${formatRupiah(amount - _wallet.balance)}',
      );
    }

    final transaction = WalletTransaction(
      userId: _wallet.userId,
      type: WalletTransactionType.purchase,
      amount: amount,
      balanceBefore: _wallet.balance,
      balanceAfter: _wallet.balance - amount,
      referenceId: 'renew:$subscriptionId:$billingCycleMonths',
    );
    _wallet = Wallet(userId: _wallet.userId, balance: transaction.balanceAfter);
    _transactions.insert(0, transaction);
    _invoices.insert(0, _invoiceFrom(transaction));
    _subscriptions[index] = subscription.copyWith(
      status: SubscriptionStatus.active,
      billingCycleMonths: billingCycleMonths,
      expiresAt: subscription.expiresAt.add(
        Duration(days: 30 * billingCycleMonths),
      ),
    );

    return _snapshot(
      message: '${product.name} diperpanjang $billingCycleMonths bulan.',
    );
  }

  @override
  Future<BillingSnapshot> upgradeIptvSubscriptionDevices({
    required String subscriptionId,
    required int additionalDeviceCount,
  }) async {
    return _upgradeSubscriptionDevices(
      subscriptionId: subscriptionId,
      additionalDeviceCount: additionalDeviceCount,
      productId: 'costik-iptv',
    );
  }

  @override
  Future<BillingSnapshot> upgradeSignageSubscriptionDevices({
    required String subscriptionId,
    required int additionalDeviceCount,
  }) async {
    return _upgradeSubscriptionDevices(
      subscriptionId: subscriptionId,
      additionalDeviceCount: additionalDeviceCount,
      productId: 'costik-signage',
    );
  }

  Future<BillingSnapshot> _upgradeSubscriptionDevices({
    required String subscriptionId,
    required int additionalDeviceCount,
    required String productId,
  }) async {
    if (additionalDeviceCount <= 0) {
      throw ArgumentError.value(
        additionalDeviceCount,
        'additionalDeviceCount',
        'Additional device count must be greater than zero.',
      );
    }

    final index = _subscriptions.indexWhere(
      (subscription) => subscription.id == subscriptionId,
    );
    if (index == -1) {
      throw ArgumentError.value(
        subscriptionId,
        'subscriptionId',
        'Unknown subscription.',
      );
    }

    final subscription = _subscriptions[index];
    final product = dummyBillingProductById(subscription.productId);
    if (product == null || product.id != productId) {
      throw ArgumentError.value(
        subscription.productId,
        'productId',
        'Only $productId subscription is supported.',
      );
    }

    final remainingDays = _remainingSubscriptionDays(subscription);
    final amount = _proratedUpgradeAmount(
      productId: product.id,
      additionalDeviceCount: additionalDeviceCount,
      remainingDays: remainingDays,
    );

    if (_wallet.balance < amount) {
      return _snapshot(
        message: 'Saldo kurang ${formatRupiah(amount - _wallet.balance)}',
      );
    }

    final transaction = WalletTransaction(
      userId: _wallet.userId,
      type: WalletTransactionType.purchase,
      amount: amount,
      balanceBefore: _wallet.balance,
      balanceAfter: _wallet.balance - amount,
      referenceId:
          'upgrade-device:$subscriptionId:$additionalDeviceCount:$remainingDays-days',
    );
    _wallet = Wallet(userId: _wallet.userId, balance: transaction.balanceAfter);
    _transactions.insert(0, transaction);
    _invoices.insert(0, _invoiceFrom(transaction));
    _subscriptions[index] = subscription.copyWith(
      status: SubscriptionStatus.active,
      deviceCount: subscription.deviceCount + additionalDeviceCount,
    );

    return _snapshot(
      message:
          '${product.name} ditambah $additionalDeviceCount device prorata $remainingDays hari.',
    );
  }

  @override
  Future<BillingSnapshot> reactivateIptvSubscription({
    required String subscriptionId,
  }) async {
    return _reactivateSubscription(
      subscriptionId: subscriptionId,
      productId: 'costik-iptv',
    );
  }

  @override
  Future<BillingSnapshot> reactivateSignageSubscription({
    required String subscriptionId,
  }) async {
    return _reactivateSubscription(
      subscriptionId: subscriptionId,
      productId: 'costik-signage',
    );
  }

  Future<BillingSnapshot> _reactivateSubscription({
    required String subscriptionId,
    required String productId,
  }) async {
    final index = _subscriptions.indexWhere(
      (subscription) => subscription.id == subscriptionId,
    );
    if (index == -1) {
      throw ArgumentError.value(
        subscriptionId,
        'subscriptionId',
        'Unknown subscription.',
      );
    }

    final subscription = _subscriptions[index];
    final product = dummyBillingProductById(subscription.productId);
    if (product == null || product.id != productId) {
      throw ArgumentError.value(
        subscription.productId,
        'productId',
        'Only $productId subscription reactivation is supported.',
      );
    }

    _subscriptions[index] = subscription.copyWith(
      status: SubscriptionStatus.active,
    );

    return _snapshot(
      message: 'Langganan ${product.name} berhasil diaktifkan kembali.',
    );
  }

  @override
  Future<BillingSnapshot> cancelIptvSubscription({
    required String subscriptionId,
  }) async {
    return _cancelSubscription(
      subscriptionId: subscriptionId,
      productId: 'costik-iptv',
    );
  }

  @override
  Future<BillingSnapshot> cancelSignageSubscription({
    required String subscriptionId,
  }) async {
    return _cancelSubscription(
      subscriptionId: subscriptionId,
      productId: 'costik-signage',
    );
  }

  Future<BillingSnapshot> _cancelSubscription({
    required String subscriptionId,
    required String productId,
  }) async {
    final index = _subscriptions.indexWhere(
      (subscription) => subscription.id == subscriptionId,
    );
    if (index == -1) {
      throw ArgumentError.value(
        subscriptionId,
        'subscriptionId',
        'Unknown subscription.',
      );
    }

    final subscription = _subscriptions[index];
    final product = dummyBillingProductById(subscription.productId);
    final productName = product?.name ?? shortNameForProductId(productId);
    _subscriptions[index] = subscription.copyWith(
      status: SubscriptionStatus.cancelled,
    );

    return _snapshot(message: 'Langganan $productName berhasil dibatalkan.');
  }

  @override
  Future<BillingSnapshot> setSubscriptionAutoRenew({
    required String subscriptionId,
    required bool autoRenew,
  }) async {
    final index = _subscriptions.indexWhere(
      (subscription) => subscription.id == subscriptionId,
    );
    if (index == -1) {
      throw ArgumentError.value(
        subscriptionId,
        'subscriptionId',
        'Unknown subscription.',
      );
    }

    final subscription = _subscriptions[index];
    _subscriptions[index] = subscription.copyWith(autoRenew: autoRenew);
    return _snapshot(
      message: autoRenew
          ? 'Auto-renew ${subscription.productId} diaktifkan.'
          : 'Auto-renew ${subscription.productId} dimatikan.',
    );
  }

  Future<BillingSnapshot> _checkout({
    required BillingPlan plan,
    bool autoRenew = false,
  }) async {
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
        autoRenew: autoRenew,
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

  int _remainingSubscriptionDays(Subscription subscription) {
    final remaining = subscription.expiresAt
        .difference(DateTime(2026, 9, 9))
        .inDays;
    return remaining <= 0 ? 1 : remaining;
  }

  int _proratedUpgradeAmount({
    required String productId,
    required int additionalDeviceCount,
    required int remainingDays,
  }) {
    final unitPrice = unitPriceForProductId(productId);
    final amount = additionalDeviceCount * unitPrice * remainingDays / 30;
    return amount.ceil();
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

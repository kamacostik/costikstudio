class Wallet {
  const Wallet({required this.userId, required this.balance});

  final String userId;
  final int balance;

  WalletMutationResult applyTopUp({
    required int amount,
    required String referenceId,
  }) {
    _guardPositiveAmount(amount);
    final nextBalance = balance + amount;
    return WalletMutationResult(
      wallet: Wallet(userId: userId, balance: nextBalance),
      transaction: WalletTransaction(
        userId: userId,
        type: WalletTransactionType.topup,
        amount: amount,
        balanceBefore: balance,
        balanceAfter: nextBalance,
        referenceId: referenceId,
      ),
    );
  }
}

enum WalletTransactionType { topup, purchase, refund, adjustment, bonus }

class WalletTransaction {
  const WalletTransaction({
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.referenceId,
  });

  final String userId;
  final WalletTransactionType type;
  final int amount;
  final int balanceBefore;
  final int balanceAfter;
  final String referenceId;
}

class WalletMutationResult {
  const WalletMutationResult({required this.wallet, required this.transaction});

  final Wallet wallet;
  final WalletTransaction transaction;
}

enum BillingProductCategory { signage, iptv, hris, pos, laundry, booking }

class BillingProduct {
  const BillingProduct({
    required this.id,
    required this.name,
    required this.category,
  });

  final String id;
  final String name;
  final BillingProductCategory category;
}

class BillingPlan {
  const BillingPlan({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.durationDays,
    required this.features,
  });

  final String id;
  final String productId;
  final String name;
  final int price;
  final int durationDays;
  final List<String> features;
}

enum SubscriptionStatus {
  trial,
  active,
  gracePeriod,
  expired,
  cancelled,
  suspended,
}

class Subscription {
  const Subscription({
    required this.id,
    required this.userId,
    required this.productId,
    required this.planId,
    required this.status,
    required this.startedAt,
    required this.expiresAt,
    required this.autoRenew,
  });

  final String id;
  final String userId;
  final String productId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool autoRenew;

  Subscription copyWith({
    String? id,
    String? userId,
    String? productId,
    String? planId,
    SubscriptionStatus? status,
    DateTime? startedAt,
    DateTime? expiresAt,
    bool? autoRenew,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      autoRenew: autoRenew ?? this.autoRenew,
    );
  }
}

enum BillingInvoiceType { topup, subscription }

enum BillingInvoiceStatus { draft, paid, voided }

class BillingInvoice {
  const BillingInvoice({
    required this.number,
    required this.userId,
    required this.type,
    required this.status,
    required this.amount,
    required this.issuedAt,
    required this.paidAt,
    required this.referenceId,
  });

  final String number;
  final String userId;
  final BillingInvoiceType type;
  final BillingInvoiceStatus status;
  final int amount;
  final DateTime issuedAt;
  final DateTime? paidAt;
  final String referenceId;

  factory BillingInvoice.fromWalletTransaction({
    required WalletTransaction transaction,
    required String number,
    required DateTime issuedAt,
  }) {
    return BillingInvoice(
      number: number,
      userId: transaction.userId,
      type: switch (transaction.type) {
        WalletTransactionType.topup => BillingInvoiceType.topup,
        WalletTransactionType.purchase => BillingInvoiceType.subscription,
        WalletTransactionType.refund => BillingInvoiceType.subscription,
        WalletTransactionType.adjustment => BillingInvoiceType.subscription,
        WalletTransactionType.bonus => BillingInvoiceType.topup,
      },
      status: BillingInvoiceStatus.paid,
      amount: transaction.amount,
      issuedAt: issuedAt,
      paidAt: issuedAt,
      referenceId: transaction.referenceId,
    );
  }
}

class CheckoutResult {
  const CheckoutResult({
    required this.wallet,
    required this.transaction,
    required this.subscription,
  });

  final Wallet wallet;
  final WalletTransaction transaction;
  final Subscription subscription;
}

class BillingCheckout {
  const BillingCheckout._();

  static CheckoutResult checkoutPlan({
    required Wallet wallet,
    required BillingProduct product,
    required BillingPlan plan,
    required DateTime now,
    Subscription? existingSubscription,
  }) {
    if (plan.productId != product.id) {
      throw ArgumentError('Plan does not belong to selected product.');
    }
    _guardPositiveAmount(plan.price);
    if (wallet.balance < plan.price) {
      throw InsufficientBalanceException(
        balance: wallet.balance,
        requiredAmount: plan.price,
      );
    }

    final nextBalance = wallet.balance - plan.price;
    final baseDate = _renewalBaseDate(existingSubscription, now);
    final nextSubscription = _buildSubscription(
      wallet: wallet,
      product: product,
      plan: plan,
      now: now,
      baseDate: baseDate,
      existingSubscription: existingSubscription,
    );

    return CheckoutResult(
      wallet: Wallet(userId: wallet.userId, balance: nextBalance),
      transaction: WalletTransaction(
        userId: wallet.userId,
        type: WalletTransactionType.purchase,
        amount: plan.price,
        balanceBefore: wallet.balance,
        balanceAfter: nextBalance,
        referenceId: 'checkout:${product.id}:${plan.id}',
      ),
      subscription: nextSubscription,
    );
  }

  static DateTime _renewalBaseDate(
    Subscription? existingSubscription,
    DateTime now,
  ) {
    if (existingSubscription == null) return now;
    if (existingSubscription.status == SubscriptionStatus.active &&
        existingSubscription.expiresAt.isAfter(now)) {
      return existingSubscription.expiresAt;
    }
    return now;
  }

  static Subscription _buildSubscription({
    required Wallet wallet,
    required BillingProduct product,
    required BillingPlan plan,
    required DateTime now,
    required DateTime baseDate,
    required Subscription? existingSubscription,
  }) {
    final expiresAt = baseDate.add(Duration(days: plan.durationDays));
    if (existingSubscription != null) {
      return existingSubscription.copyWith(
        planId: plan.id,
        status: SubscriptionStatus.active,
        expiresAt: expiresAt,
      );
    }

    return Subscription(
      id: 'sub:${wallet.userId}:${product.id}',
      userId: wallet.userId,
      productId: product.id,
      planId: plan.id,
      status: SubscriptionStatus.active,
      startedAt: now,
      expiresAt: expiresAt,
      autoRenew: false,
    );
  }
}

class InsufficientBalanceException implements Exception {
  const InsufficientBalanceException({
    required this.balance,
    required this.requiredAmount,
  });

  final int balance;
  final int requiredAmount;

  int get shortfall => requiredAmount - balance;

  @override
  String toString() {
    return 'InsufficientBalanceException(balance: $balance, requiredAmount: $requiredAmount)';
  }
}

void _guardPositiveAmount(int amount) {
  if (amount <= 0) {
    throw ArgumentError.value(
      amount,
      'amount',
      'Amount must be greater than zero.',
    );
  }
}

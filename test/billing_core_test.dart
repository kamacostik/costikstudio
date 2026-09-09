import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Billing Core Phase 1', () {
    test('creates wallet top up transaction and increases balance', () {
      const wallet = Wallet(userId: 'user-1', balance: 50000);

      final result = wallet.applyTopUp(
        amount: 100000,
        referenceId: 'topup-001',
      );

      expect(result.wallet.balance, 150000);
      expect(result.transaction.type, WalletTransactionType.topup);
      expect(result.transaction.amount, 100000);
      expect(result.transaction.balanceBefore, 50000);
      expect(result.transaction.balanceAfter, 150000);
      expect(result.transaction.referenceId, 'topup-001');
    });

    test('checkout activates subscription when wallet balance is enough', () {
      const wallet = Wallet(userId: 'user-1', balance: 200000);
      const product = BillingProduct(
        id: 'costik-signage',
        name: 'Costik Signage',
        category: BillingProductCategory.signage,
      );
      const plan = BillingPlan(
        id: 'signage-pro',
        productId: 'costik-signage',
        name: 'Pro',
        price: 150000,
        durationDays: 30,
        features: ['10 screens', '3 locations'],
      );
      final now = DateTime(2026, 9, 9);

      final result = BillingCheckout.checkoutPlan(
        wallet: wallet,
        product: product,
        plan: plan,
        now: now,
      );

      expect(result.wallet.balance, 50000);
      expect(result.transaction.type, WalletTransactionType.purchase);
      expect(result.transaction.balanceBefore, 200000);
      expect(result.transaction.balanceAfter, 50000);
      expect(result.subscription.status, SubscriptionStatus.active);
      expect(result.subscription.productId, 'costik-signage');
      expect(result.subscription.planId, 'signage-pro');
      expect(result.subscription.startedAt, now);
      expect(result.subscription.expiresAt, now.add(const Duration(days: 30)));
    });

    test('checkout rejects purchase when wallet balance is insufficient', () {
      const wallet = Wallet(userId: 'user-1', balance: 80000);
      const product = BillingProduct(
        id: 'costik-iptv',
        name: 'Costik IPTV',
        category: BillingProductCategory.iptv,
      );
      const plan = BillingPlan(
        id: 'iptv-hotel-pro',
        productId: 'costik-iptv',
        name: 'Hotel Pro',
        price: 300000,
        durationDays: 30,
        features: ['50 rooms'],
      );

      expect(
        () => BillingCheckout.checkoutPlan(
          wallet: wallet,
          product: product,
          plan: plan,
          now: DateTime(2026, 9, 9),
        ),
        throwsA(
          isA<InsufficientBalanceException>().having(
            (error) => error.shortfall,
            'shortfall',
            220000,
          ),
        ),
      );
    });

    test(
      'manual renew extends active subscription from current expiry date',
      () {
        const wallet = Wallet(userId: 'user-1', balance: 200000);
        final existingSubscription = Subscription(
          id: 'sub-1',
          userId: 'user-1',
          productId: 'costik-hris',
          planId: 'hris-starter',
          status: SubscriptionStatus.active,
          startedAt: DateTime(2026, 9, 1),
          expiresAt: DateTime(2026, 10, 1),
          autoRenew: false,
        );
        const product = BillingProduct(
          id: 'costik-hris',
          name: 'Costik HRIS',
          category: BillingProductCategory.hris,
        );
        const plan = BillingPlan(
          id: 'hris-starter',
          productId: 'costik-hris',
          name: 'Starter',
          price: 75000,
          durationDays: 30,
          features: ['10 employees'],
        );

        final result = BillingCheckout.checkoutPlan(
          wallet: wallet,
          product: product,
          plan: plan,
          existingSubscription: existingSubscription,
          now: DateTime(2026, 9, 15),
        );

        expect(result.wallet.balance, 125000);
        expect(result.subscription.startedAt, DateTime(2026, 9, 1));
        expect(result.subscription.expiresAt, DateTime(2026, 10, 31));
      },
    );
  });
}

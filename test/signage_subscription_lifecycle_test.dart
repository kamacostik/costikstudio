import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/billing/billing_pricing.dart';
import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Signage subscription lifecycle mirrors IPTV at 20rb/device', () {
    test('checkout charges 20rb per device per month', () async {
      final repository = DummyBillingRepository();
      final before = await repository.loadSnapshot();

      final snapshot = await repository.checkoutSignageSubscription(
        deviceCount: 2,
        billingCycleMonths: 1,
      );

      final expected = 2 * signagePricePerDevice;
      expect(snapshot.wallet.balance, before.wallet.balance - expected);
      final signageAfter = snapshot.subscriptions.firstWhere(
        (s) => s.productId == 'costik-signage',
      );
      expect(signageAfter.status, SubscriptionStatus.active);
      expect(
        snapshot.transactions.first.referenceId,
        'checkout:costik-signage:costik-signage:custom',
      );
    });

    test('renew charges 20rb per device', () async {
      final repository = DummyBillingRepository();
      final before = await repository.loadSnapshot();
      final signage = before.subscriptions.firstWhere(
        (s) => s.productId == 'costik-signage',
      );

      final snapshot = await repository.renewSignageSubscription(
        subscriptionId: signage.id,
        billingCycleMonths: 1,
      );

      final expected = signage.deviceCount * signagePricePerDevice;
      expect(snapshot.wallet.balance, before.wallet.balance - expected);
      expect(snapshot.transactions.first.referenceId, 'renew:${signage.id}:1');
    });

    test('upgrade charges prorated 20rb rate', () async {
      final repository = DummyBillingRepository();
      final before = await repository.loadSnapshot();
      final signage = before.subscriptions.firstWhere(
        (s) => s.productId == 'costik-signage',
      );
      final remaining = signage.expiresAt
          .difference(DateTime(2026, 9, 9))
          .inDays;
      final safeRemaining = remaining <= 0 ? 1 : remaining;
      final expected = (1 * signagePricePerDevice * safeRemaining / 30).ceil();

      final snapshot = await repository.upgradeSignageSubscriptionDevices(
        subscriptionId: signage.id,
        additionalDeviceCount: 1,
      );

      expect(snapshot.wallet.balance, before.wallet.balance - expected);
      final after = snapshot.subscriptions.firstWhere(
        (s) => s.id == signage.id,
      );
      expect(after.deviceCount, signage.deviceCount + 1);
      expect(
        snapshot.transactions.first.referenceId,
        'upgrade-device:${signage.id}:1:$safeRemaining-days',
      );
    });

    test('cancel then reactivate toggles status without charge', () async {
      final repository = DummyBillingRepository();
      final before = await repository.loadSnapshot();
      final signage = before.subscriptions.firstWhere(
        (s) => s.productId == 'costik-signage',
      );

      final cancelled = await repository.cancelSignageSubscription(
        subscriptionId: signage.id,
      );
      expect(
        cancelled.subscriptions.firstWhere((s) => s.id == signage.id).status,
        SubscriptionStatus.cancelled,
      );

      final reactivated = await repository.reactivateSignageSubscription(
        subscriptionId: signage.id,
      );
      expect(
        reactivated.subscriptions.firstWhere((s) => s.id == signage.id).status,
        SubscriptionStatus.active,
      );
      expect(
        reactivated.wallet.balance,
        cancelled.wallet.balance,
        reason: 'reactivation must not charge the wallet',
      );
    });

    test('pricing table keeps signage at 20rb and iptv at 15rb', () {
      expect(signagePricePerDevice, 20000);
      expect(iptvPricePerDevice, 15000);
      expect(unitPriceForProductId('costik-signage'), 20000);
      expect(unitPriceForProductId('costik-iptv'), 15000);
      expect(formatRupiah(signagePricePerDevice), contains('20'));
    });

    test('checkout with auto-renew stores the flag', () async {
      final repository = DummyBillingRepository();

      final snapshot = await repository.checkoutSignageSubscription(
        deviceCount: 1,
        billingCycleMonths: 1,
        autoRenew: true,
      );

      final signage = snapshot.subscriptions.firstWhere(
        (s) => s.productId == 'costik-signage',
      );
      expect(signage.autoRenew, isTrue);

      final toggled = await repository.setSubscriptionAutoRenew(
        subscriptionId: signage.id,
        autoRenew: false,
      );
      expect(
        toggled.subscriptions.firstWhere((s) => s.id == signage.id).autoRenew,
        isFalse,
      );
    });
  });
}

import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/dummy_billing_data.dart';
import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renewIptvSubscription extends active IPTV subscription and invoices wallet', () async {
    final repository = DummyBillingRepository();
    final before = await repository.loadSnapshot();
    final beforeSubscription = before.subscriptions.firstWhere(
      (subscription) => subscription.productId == 'costik-iptv',
    );

    final snapshot = await repository.renewIptvSubscription(
      subscriptionId: beforeSubscription.id,
      billingCycleMonths: 1,
    );
    final afterSubscription = snapshot.subscriptions.firstWhere(
      (subscription) => subscription.id == beforeSubscription.id,
    );

    expect(snapshot.wallet.balance, before.wallet.balance - 250000);
    expect(
      afterSubscription.expiresAt.isAfter(beforeSubscription.expiresAt),
      isTrue,
    );
    expect(
      snapshot.transactions.first.referenceId,
      'renew:${beforeSubscription.id}:1',
    );
    expect(snapshot.invoices.first.amount, 250000);
    expect(snapshot.message, 'Costik IPTV diperpanjang 1 bulan.');
  });

  test(
    'expired subscriptions are exposed as expired in billing snapshots',
    () async {
      final expired = dummySubscriptions
          .firstWhere((subscription) => subscription.productId == 'costik-iptv')
          .copyWith(
            status: SubscriptionStatus.active,
            expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          );
      final repository = DummyBillingRepository(seedSubscriptions: [expired]);

      final snapshot = await repository.loadSnapshot();

      expect(snapshot.subscriptions.single.status, SubscriptionStatus.expired);
    },
  );

  test(
    'renewIptvSubscription renews expired subscription from today',
    () async {
      final expired = dummySubscriptions
          .firstWhere((subscription) => subscription.productId == 'costik-iptv')
          .copyWith(
            status: SubscriptionStatus.active,
            expiresAt: DateTime.now().subtract(const Duration(days: 1)),
          );
      final repository = DummyBillingRepository(seedSubscriptions: [expired]);

      final snapshot = await repository.renewIptvSubscription(
        subscriptionId: expired.id,
        billingCycleMonths: 1,
      );

      final renewed = snapshot.subscriptions.single;
      expect(renewed.status, SubscriptionStatus.active);
      expect(
        renewed.expiresAt.isAfter(DateTime.now().add(const Duration(days: 28))),
        isTrue,
      );
    },
  );
}

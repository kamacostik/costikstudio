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

    expect(snapshot.wallet.balance, before.wallet.balance - 100000);
    expect(
      afterSubscription.expiresAt.isAfter(beforeSubscription.expiresAt),
      isTrue,
    );
    expect(
      snapshot.transactions.first.referenceId,
      'renew:${beforeSubscription.id}:1',
    );
    expect(snapshot.invoices.first.amount, 100000);
    expect(snapshot.message, 'Costik IPTV diperpanjang 1 bulan.');
  });
}

import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cancelIptvSubscription set subscription status to cancelled', () async {
    final repository = DummyBillingRepository();
    final before = await repository.loadSnapshot();
    final beforeSubscription = before.subscriptions.firstWhere(
      (subscription) => subscription.productId == 'costik-iptv',
    );

    final snapshot = await repository.cancelIptvSubscription(
      subscriptionId: beforeSubscription.id,
    );
    final afterSubscription = snapshot.subscriptions.firstWhere(
      (subscription) => subscription.id == beforeSubscription.id,
    );

    expect(afterSubscription.status, SubscriptionStatus.cancelled);
    expect(snapshot.message, 'Langganan Costik IPTV berhasil dibatalkan.');
  });
}

import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'reactivateIptvSubscription changes cancelled subscription to active',
    () async {
      final repository = DummyBillingRepository();
      final before = await repository.loadSnapshot();
      final subscription = before.subscriptions.firstWhere(
        (subscription) => subscription.productId == 'costik-iptv',
      );

      final cancelled = await repository.cancelIptvSubscription(
        subscriptionId: subscription.id,
      );
      expect(
        cancelled.subscriptions
            .firstWhere((item) => item.id == subscription.id)
            .status,
        SubscriptionStatus.cancelled,
      );

      final reactivated = await repository.reactivateIptvSubscription(
        subscriptionId: subscription.id,
      );

      final afterSubscription = reactivated.subscriptions.firstWhere(
        (item) => item.id == subscription.id,
      );
      expect(afterSubscription.status, SubscriptionStatus.active);
      expect(
        reactivated.message,
        'Langganan Costik IPTV berhasil diaktifkan kembali.',
      );
    },
  );
}

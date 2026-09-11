import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'upgradeIptvSubscriptionDevices increases devices and invoices wallet',
    () async {
      final repository = DummyBillingRepository();
      final before = await repository.loadSnapshot();
      final beforeSubscription = before.subscriptions.firstWhere(
        (subscription) => subscription.productId == 'costik-iptv',
      );

      final snapshot = await repository.upgradeIptvSubscriptionDevices(
        subscriptionId: beforeSubscription.id,
        additionalDeviceCount: 2,
      );
      final afterSubscription = snapshot.subscriptions.firstWhere(
        (subscription) => subscription.id == beforeSubscription.id,
      );

      expect(afterSubscription.deviceCount, beforeSubscription.deviceCount + 2);
      expect(snapshot.wallet.balance, before.wallet.balance - 30000);
      expect(
        snapshot.transactions.first.referenceId,
        'upgrade-device:${beforeSubscription.id}:2',
      );
      expect(snapshot.invoices.first.amount, 30000);
      expect(snapshot.message, 'Costik IPTV ditambah 2 device.');
    },
  );
}

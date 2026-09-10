import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DummyBillingRepository', () {
    test('loads initial billing snapshot from dummy data', () async {
      final repository = DummyBillingRepository();

      final snapshot = await repository.loadSnapshot();

      expect(snapshot.wallet.balance, 350000);
      expect(
        snapshot.products.map((product) => product.id),
        contains('costik-signage'),
      );
      expect(snapshot.plans.map((plan) => plan.id), contains('iptv-hotel-pro'));
      expect(snapshot.subscriptions.length, 2);
      expect(snapshot.transactions.length, 1);
      expect(snapshot.invoices.length, 1);
    });

    test('top up mutates wallet, transactions, and invoices', () async {
      final repository = DummyBillingRepository();

      final order = await repository.topUp(amount: 100000);
      final snapshot = await repository.loadSnapshot();

      expect(order?.externalReference, 'dummy-topup-100000');
      expect(snapshot.wallet.balance, 450000);
      expect(snapshot.transactions.first.type.name, 'topup');
      expect(snapshot.invoices.first.number, 'INV-20260909-002');
      expect(snapshot.invoices.first.amount, 100000);
    });

    test(
      'checkout mutates wallet, subscriptions, transactions, and invoices',
      () async {
        final repository = DummyBillingRepository();

        final snapshot = await repository.checkoutPlan(planId: 'hris-starter');

        expect(snapshot.wallet.balance, 275000);
        expect(
          snapshot.subscriptions.map((subscription) => subscription.productId),
          contains('costik-hris'),
        );
        expect(
          snapshot.transactions.first.referenceId,
          'checkout:costik-hris:hris-starter',
        );
        expect(snapshot.invoices.first.amount, 75000);
      },
    );
  });
}

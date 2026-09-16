import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:costikstudio/features/billing/cubit/billing_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillingCubit', () {
    test('loads billing snapshot', () async {
      final cubit = BillingCubit(repository: DummyBillingRepository());

      await cubit.load();

      expect(cubit.state.status, BillingStatus.success);
      expect(cubit.state.snapshot?.wallet.balance, 350000);
    });

    test('top up updates state snapshot and message', () async {
      final cubit = BillingCubit(repository: DummyBillingRepository());
      await cubit.load();

      await cubit.topUpDummy();

      expect(cubit.state.snapshot?.wallet.balance, 450000);
      expect(
        cubit.state.snapshot?.message,
        'Payment order dummy-topup-100000 dibuat untuk 100000.',
      );
    });

    test('checkout updates state snapshot and message', () async {
      final cubit = BillingCubit(repository: DummyBillingRepository());
      await cubit.load();

      await cubit.checkoutPlan('hris-starter');

      expect(cubit.state.snapshot?.wallet.balance, 275000);
      expect(cubit.state.snapshot?.message, 'Costik HRIS Starter aktif');
    });

    test('passes IPTV voucher code to subscription checkout', () async {
      final repository = DummyBillingRepository();
      final cubit = BillingCubit(repository: repository);
      await cubit.load();
      await cubit.topUp(amount: 2000000);

      await cubit.checkoutIptvSubscription(
        deviceCount: 100,
        billingCycleMonths: 1,
        voucherCode: 'WELCOME20',
      );

      expect(cubit.state.status, BillingStatus.success);
      expect(cubit.state.snapshot?.wallet.balance, 750000);
      expect(cubit.state.snapshot?.message, contains('WELCOME20'));
    });
  });
}

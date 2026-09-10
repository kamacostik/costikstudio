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
  });
}

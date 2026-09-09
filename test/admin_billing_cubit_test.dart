import 'package:costikstudio/features/billing/admin/admin_billing_cubit.dart';
import 'package:costikstudio/features/billing/admin/dummy_admin_billing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminBillingCubit', () {
    test('loads admin billing snapshot', () async {
      final cubit = AdminBillingCubit(
        repository: DummyAdminBillingRepository(),
      );

      await cubit.load();

      expect(cubit.state.status, AdminBillingStatus.success);
      expect(cubit.state.snapshot?.pendingTopUps.length, 1);
      expect(cubit.state.snapshot?.customerWallets.length, 2);
    });

    test('approves pending top up and updates message', () async {
      final cubit = AdminBillingCubit(
        repository: DummyAdminBillingRepository(),
      );
      await cubit.load();

      await cubit.approveTopUp('topup-kendari-hotel');

      expect(cubit.state.snapshot?.pendingTopUps, isEmpty);
      expect(
        cubit.state.snapshot?.message,
        'Top up Kendari Hotel Group disetujui',
      );
    });
  });
}

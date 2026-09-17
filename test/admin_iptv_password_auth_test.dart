import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'CostikStudio lets active IPTV users create Admin IPTV auth password',
    () {
      final authCubit = File('lib/features/auth/cubit/auth_cubit.dart')
          .readAsStringSync();
      final subscriptionsCard = File(
        'lib/features/billing/widgets/subscriptions_card.dart',
      ).readAsStringSync();

      expect(authCubit, contains('setAdminIptvPassword'));
      expect(authCubit, contains('updateUser'));
      expect(authCubit, contains('UserAttributes(password'));
      expect(subscriptionsCard, contains('Create Admin Password'));
      expect(
        subscriptionsCard,
        contains("subscription.productId == 'costik-iptv'"),
      );
      expect(subscriptionsCard, contains('setAdminIptvPassword'));
      expect(subscriptionsCard, isNot(contains('admin_iptv_password')));
    },
  );
}

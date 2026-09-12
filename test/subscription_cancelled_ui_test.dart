import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/dummy_billing_data.dart';
import 'package:costikstudio/features/billing/widgets/subscriptions_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'cancelled subscription disables renew and upgrade and shows reactivate action',
    (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final subscription = dummySubscriptions
          .firstWhere((subscription) => subscription.productId == 'costik-iptv')
          .copyWith(status: SubscriptionStatus.cancelled);

      var reactivatedSubscriptionId = '';

      await tester.pumpWidget(
        MaterialApp(
          theme: CostikStudioTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: SubscriptionsCard(
                products: dummyBillingProducts,
                plans: dummyBillingPlans,
                subscriptions: [subscription],
                onRenew: ({
                  required billingCycleMonths,
                  required subscriptionId,
                }) async {},
                onUpgradeDevice: ({
                  required additionalDeviceCount,
                  required subscriptionId,
                }) async {},
                onCancel: ({required subscriptionId}) async {},
                onReactivate: ({required subscriptionId}) async {
                  reactivatedSubscriptionId = subscriptionId;
                },
                onToggleAutoRenew: ({
                  required subscriptionId,
                  required bool autoRenew,
                }) async {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InactiveSubscriptionNotice), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Aktifkan Kembali'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OutlinedButton, 'Upgrade Device'),
        findsNothing,
      );
      expect(find.widgetWithText(FilledButton, 'Renew'), findsNothing);

      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'Aktifkan Kembali'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Aktifkan Kembali'));
      await tester.pump();

      expect(reactivatedSubscriptionId, subscription.id);
      expect(
        find.text('Memproses aktivasi ulang subscription...'),
        findsOneWidget,
      );
    },
  );
}

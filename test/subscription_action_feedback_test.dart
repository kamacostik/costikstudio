import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_login_helper.dart';

void main() {
  testWidgets('renew action shows visible feedback after choosing duration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await loginAsCustomer(tester);
    await tester.tap(find.byKey(const Key('header_nav_/billing')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard_nav_subscriptions')));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Renew').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FilledButton).last);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Memproses renewal subscription...'), findsOneWidget);
  });

  testWidgets(
    'upgrade device action shows visible feedback after choosing device',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CostikStudioApp());
      await tester.pumpAndSettle();

      await loginAsCustomer(tester);
      await tester.tap(find.byKey(const Key('header_nav_/billing')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard_nav_subscriptions')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Upgrade Device').first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Memproses upgrade device...'), findsOneWidget);
    },
  );
}

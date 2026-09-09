import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dummy checkout purchases plan and updates wallet activity', (
    tester,
  ) async {
    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header_login_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill Customer (user@costik.com)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header_nav_/billing')));
    await tester.pumpAndSettle();
    final subscribeButton = find.widgetWithText(OutlinedButton, 'Renew Basic');
    await tester.ensureVisible(subscribeButton);
    await tester.tap(subscribeButton);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard_nav_billing')));
    await tester.pumpAndSettle();
    expect(find.text('Rp 300.000'), findsWidgets);

    await tester.tap(find.byKey(const Key('dashboard_nav_activity')));
    await tester.pumpAndSettle();
    expect(find.text('Plan purchase'), findsWidgets);
    await tester.tap(find.byKey(const Key('dashboard_nav_subscriptions')));
    await tester.pumpAndSettle();
    expect(find.text('Basic • expires 31/10/2026'), findsOneWidget);
  });

  testWidgets('dummy checkout shows shortfall when wallet is not enough', (
    tester,
  ) async {
    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header_login_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill Customer (user@costik.com)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header_nav_/billing')));
    await tester.pumpAndSettle();
    final subscribeButton = find.widgetWithText(
      OutlinedButton,
      'Renew Hotel Pro',
    );
    await tester.ensureVisible(subscribeButton);
    await tester.tap(subscribeButton);
    await tester.pumpAndSettle();
    await tester.tap(subscribeButton);
    await tester.pumpAndSettle();

    expect(find.text('Saldo kurang Rp 250.000'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dashboard_nav_billing')));
    await tester.pumpAndSettle();
    expect(find.text('Rp 50.000'), findsWidgets);
  });
}

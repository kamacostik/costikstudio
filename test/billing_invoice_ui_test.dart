import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('billing dashboard shows invoices from dummy transactions', (
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

    expect(find.text('Invoices'), findsOneWidget);
    expect(find.text('INV-20260909-001'), findsOneWidget);
    expect(find.text('Subscription payment'), findsOneWidget);
    expect(find.text('Paid Rp 150.000'), findsOneWidget);
  });

  testWidgets('top up creates visible paid top up invoice', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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
    final topUpButton = find.widgetWithText(
      FilledButton,
      'Top up dummy Rp100.000',
    );
    await tester.ensureVisible(topUpButton);
    await tester.tap(topUpButton);
    await tester.pumpAndSettle();

    expect(find.text('INV-20260909-002'), findsOneWidget);
    expect(find.text('Top up wallet'), findsOneWidget);
    expect(find.text('Paid Rp 100.000'), findsOneWidget);
  });
}

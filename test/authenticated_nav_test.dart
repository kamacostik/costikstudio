import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_login_helper.dart';

void main() {
  testWidgets('billing and support menu show only after user login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('header_nav_/billing')), findsNothing);
    expect(find.widgetWithText(TextButton, 'Support'), findsNothing);

    await loginAsCustomer(tester);

    expect(find.text('Billing'), findsWidgets);
    expect(find.text('Support'), findsWidgets);

    await tester.tap(find.byKey(const Key('header_nav_/billing')));
    await tester.pumpAndSettle();

    expect(find.text('Produk'), findsWidgets);
  });

  testWidgets('home hero shows dashboard action after login', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await loginAsCustomer(tester);
    await tester.tap(find.byKey(const Key('header_nav_/')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Dashboard'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Login'), findsNothing);
  });
}

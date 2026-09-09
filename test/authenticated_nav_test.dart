import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('billing and support menu show only after user login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, 'Billing'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Support'), findsNothing);

    await tester.tap(find.byKey(const Key('header_login_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill Customer (user@costik.com)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Billing'), findsWidgets);
    expect(find.text('Support'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'Billing'));
    await tester.pumpAndSettle();

    expect(find.text('Billing Core'), findsOneWidget);
  });
}

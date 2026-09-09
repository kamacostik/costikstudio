import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('billing plan actions use customer-friendly labels', (
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

    expect(find.text('Aplikasi'), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, 'Renew Basic'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Renew Pro'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Renew Hotel Pro'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(OutlinedButton, 'Subscribe signage-basic'),
      findsNothing,
    );
  });
}

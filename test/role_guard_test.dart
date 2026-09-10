import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('hides Admin Billing nav for customer until logged in as admin', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    // Unauthenticated / default customer view: no Admin Billing nav
    expect(find.text('Admin Billing'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

    await tester.tap(find.byKey(const Key('header_login_button')));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke Costik Studio'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'admin@costik.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      '123456',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Masuk ke Dashboard'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk ke Dashboard'));
    await tester.pumpAndSettle();

    // User build stays separated: admin dashboard nav never appears here.
    expect(find.byIcon(Icons.admin_panel_settings_rounded), findsWidgets);
    expect(find.text('Admin Billing'), findsNothing);
    expect(find.text('Pending top ups'), findsNothing);
  });
}

import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders login page with quick fill presets and handles login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    // Click Login button from header
    await tester.tap(find.byKey(const Key('header_login_button')));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke CostikStudio'), findsOneWidget);
    expect(find.text('Fill Customer (user@costik.com)'), findsOneWidget);
    expect(find.text('Fill Admin (admin@costik.com)'), findsOneWidget);

    // Quick fill customer
    await tester.tap(find.text('Fill Customer (user@costik.com)'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    // redirected to billing & header shows user email
    expect(find.text('user@costik.com'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
  });
}

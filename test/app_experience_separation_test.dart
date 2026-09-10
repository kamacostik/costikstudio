import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_login_helper.dart';

void main() {
  testWidgets('user app does not include admin navigation or dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const CostikStudioApp(experience: AppExperience.user),
    );
    await tester.pumpAndSettle();

    expect(find.text('CostikStudio Admin'), findsNothing);
    expect(find.text('Admin Billing'), findsNothing);

    await loginAsAdmin(tester);

    expect(find.text('Admin Billing'), findsNothing);
    expect(find.text('Pending top ups'), findsNothing);
  });

  testWidgets('admin app does not include public user pages in navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const CostikStudioApp(experience: AppExperience.admin),
    );
    await tester.pumpAndSettle();

    expect(find.text('CostikStudio Admin'), findsWidgets);
    expect(find.text('Home'), findsNothing);
    expect(find.text('Products'), findsNothing);
    expect(find.text('Apps'), findsNothing);
    expect(find.text('Billing'), findsNothing);
    expect(find.text('Support'), findsNothing);
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

    expect(find.text('Pending top ups'), findsOneWidget);
    expect(find.text('Customer wallets'), findsOneWidget);
    expect(find.text('Subscription overview'), findsOneWidget);
  });
}

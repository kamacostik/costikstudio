import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

    await tester.tap(find.byKey(const Key('header_login_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fill Admin (admin@costik.com)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

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
    expect(find.text('Masuk ke CostikStudio'), findsOneWidget);

    await tester.tap(find.text('Fill Admin (admin@costik.com)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Pending top ups'), findsOneWidget);
    expect(find.text('Customer wallets'), findsOneWidget);
    expect(find.text('Subscription overview'), findsOneWidget);
  });
}

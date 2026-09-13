import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_login_helper.dart';

void main() {
  testWidgets('admin app lands on summary dashboard after login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const CostikStudioApp(experience: AppExperience.admin),
    );
    await tester.pumpAndSettle();

    await loginAsAdmin(tester);

    expect(find.text('Ringkasan Admin'), findsOneWidget);
    expect(find.text('Top Up Pending'), findsOneWidget);
    expect(find.text('Billing & Subscription'), findsOneWidget);
    expect(find.text('Signage Tenants'), findsOneWidget);
  });

  testWidgets('admin dashboard navigates to billing and signage modules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const CostikStudioApp(experience: AppExperience.admin),
    );
    await tester.pumpAndSettle();

    await loginAsAdmin(tester);

    await tester.tap(find.text('Buka Billing'));
    await tester.pumpAndSettle();
    expect(find.text('Pending top ups'), findsOneWidget);

    await tester.tap(find.byKey(const Key('header_nav_/admin/signage')));
    await tester.pumpAndSettle();
    expect(find.text('Kendari Hotel Group'), findsWidgets);
    expect(find.text('Demo Customer'), findsOneWidget);
  });
}

import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'test_login_helper.dart';

void main() {
  testWidgets('admin app redirects legacy /billing URL to admin billing', (
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

    final context = tester.element(find.text('Ringkasan Admin'));
    GoRouter.of(context).go('/billing');
    await tester.pumpAndSettle();

    expect(find.textContaining('Page Not Found'), findsNothing);
    expect(find.textContaining('No route for location: /billing'), findsNothing);
    expect(find.text('Admin Billing'), findsOneWidget);
    expect(find.text('Pending top ups'), findsOneWidget);
  });
}

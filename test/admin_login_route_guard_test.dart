import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('admin app does not send non-admin login to user billing route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const CostikStudioApp(experience: AppExperience.admin),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header_login_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'user@costik.com',
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

    expect(find.textContaining('Page Not Found'), findsNothing);
    expect(find.textContaining('No route for location: /billing'), findsNothing);
    expect(find.text('Ringkasan Admin'), findsNothing);
    expect(find.textContaining('Akun ini bukan admin'), findsOneWidget);
  });
}

import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders polished login page without dummy presets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header_login_button')));
    await tester.pumpAndSettle();

    expect(find.text('Masuk ke Costik Studio'), findsOneWidget);
    expect(
      find.text('Satu dashboard untuk billing SaaS yang lebih rapi.'),
      findsOneWidget,
    );
    expect(find.text('Masuk ke Dashboard'), findsOneWidget);
    expect(find.text('Fill Customer (user@costik.com)'), findsNothing);
    expect(find.text('Fill Admin (admin@costik.com)'), findsNothing);
    expect(find.textContaining('dummy'), findsNothing);
  });

  testWidgets('shows validation when login form is empty', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('header_login_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk ke Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });
}

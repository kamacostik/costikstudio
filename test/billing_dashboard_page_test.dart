import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders dummy billing dashboard with wallet and subscriptions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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

    expect(find.text('User Dashboard'), findsOneWidget);
    expect(find.text('Dashboard Menu'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Aplikasi'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Subscription'), findsOneWidget);
    expect(find.byKey(const Key('header_nav_/billing')), findsWidgets);
    expect(find.widgetWithText(TextButton, 'Invoice'), findsOneWidget);
    expect(find.text('Rp 350.000'), findsWidgets);
    expect(find.text('Active subscriptions'), findsOneWidget);
    expect(find.text('Costik Signage'), findsWidgets);
    expect(find.text('Costik IPTV'), findsWidgets);
    expect(find.text('Recent wallet activity'), findsOneWidget);
  });

  testWidgets('dummy top up action increases visible wallet balance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

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
    final topUpButton = find.widgetWithText(
      FilledButton,
      'Top up dummy Rp100.000',
    );
    await tester.ensureVisible(topUpButton);
    await tester.tap(topUpButton);
    await tester.pumpAndSettle();

    expect(find.text('Rp 450.000'), findsWidgets);
    expect(find.text('Dummy top up'), findsOneWidget);
  });
}

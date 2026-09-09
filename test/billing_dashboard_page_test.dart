import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders dummy billing dashboard with wallet and subscriptions', (
    tester,
  ) async {
    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Billing'));
    await tester.pumpAndSettle();

    expect(find.text('Billing Core'), findsOneWidget);
    expect(find.text('Rp 350.000'), findsWidgets);
    expect(find.text('Active subscriptions'), findsOneWidget);
    expect(find.text('Costik Signage'), findsWidgets);
    expect(find.text('Costik IPTV'), findsWidgets);
    expect(find.text('Recent wallet activity'), findsOneWidget);
  });

  testWidgets('dummy top up action increases visible wallet balance', (
    tester,
  ) async {
    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Billing'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, 'Top up dummy Rp100.000'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rp 450.000'), findsWidgets);
    expect(find.text('Dummy top up'), findsOneWidget);
  });
}

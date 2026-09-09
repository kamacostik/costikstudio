import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders dummy admin billing dashboard', (tester) async {
    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Admin Billing'));
    await tester.pumpAndSettle();

    expect(find.text('Admin Billing'), findsWidgets);
    expect(find.text('Pending top ups'), findsOneWidget);
    expect(find.text('Kendari Hotel Group'), findsWidgets);
    expect(find.text('Approve Rp 250.000'), findsOneWidget);
    expect(find.text('Customer wallets'), findsOneWidget);
    expect(find.text('Subscription overview'), findsOneWidget);
  });

  testWidgets('approves dummy top up in admin billing dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Admin Billing'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Approve Rp 250.000'));
    await tester.pumpAndSettle();

    expect(find.text('Top up Kendari Hotel Group disetujui'), findsOneWidget);
    expect(find.text('No pending top ups'), findsOneWidget);
  });
}

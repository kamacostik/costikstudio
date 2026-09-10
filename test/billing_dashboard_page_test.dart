import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders user dashboard with tabbed side navigation', (
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

    expect(find.text('SERVICES'), findsOneWidget);
    expect(find.text('BILLING'), findsOneWidget);
    expect(find.text('ACTIVITY'), findsOneWidget);
    expect(
      find.byKey(const Key('dashboard_nav_subscriptions')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dashboard_nav_billing')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_nav_invoices')), findsOneWidget);
    expect(find.text('Produk'), findsWidgets);
    expect(find.text('Costik IPTV'), findsWidgets);
    expect(find.text('Active subscriptions'), findsNothing);

    await tester.tap(find.byKey(const Key('dashboard_nav_subscriptions')));
    await tester.pumpAndSettle();

    expect(find.text('Active subscriptions'), findsOneWidget);
    expect(find.text('Recent wallet activity'), findsNothing);
  });

  testWidgets('billing menu shows wallet and top up action', (tester) async {
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
    await tester.tap(find.byKey(const Key('dashboard_nav_billing')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Top Up'));
    await tester.pumpAndSettle();
    expect(find.text('Top Up Wallet'), findsOneWidget);
    expect(find.text('Buat Payment Order'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Buat Payment Order'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Menunggu Link Pembayaran'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Tutup'));
    await tester.pumpAndSettle();

    expect(find.text('Billing Wallet'), findsWidgets);
    expect(find.text('Rp 450.000'), findsWidgets);
  });
}

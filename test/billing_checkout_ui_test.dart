import 'package:costikstudio/features/subscription/view/iptv_subscription_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders IPTV subscription page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: IptvSubscriptionPage())),
    );
    expect(find.text('Formulir Berlangganan Costik IPTV'), findsOneWidget);
    expect(find.text('Informasi Bisnis / Hotel'), findsNothing);
    expect(find.text('Auto-Renew per Bulan'), findsOneWidget);
  });
}

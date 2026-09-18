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
    expect(find.textContaining('WELCOME20'), findsNothing);
    expect(find.textContaining('LAUNCH30'), findsNothing);
  });

  testWidgets('keeps IPTV video add-on disabled while unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: IptvSubscriptionPage())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add-on Video Promo (Opsional)'), findsOneWidget);
    expect(find.text('Belum tersedia saat ini'), findsOneWidget);

    final addOnSwitch = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile).first,
    );
    expect(addOnSwitch.value, isFalse);
    expect(addOnSwitch.onChanged, isNull);
  });
}

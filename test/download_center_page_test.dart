import 'package:costikstudio/features/apps/view/apps_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders marketed app product list focused on IPTV', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppsPage())),
    );

    expect(find.text('Produk Aplikasi'), findsOneWidget);
    expect(find.text('Costik IPTV'), findsOneWidget);
    expect(find.text('Lihat informasi & berlangganan'), findsOneWidget);
    expect(find.text('Smart INV'), findsNothing);
    expect(find.text('Download Center'), findsNothing);
    expect(find.text('Download APK (v1.0.0)'), findsNothing);
  });
}

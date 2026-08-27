import 'package:costikstudio/features/apps/view/apps_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders download center page with apps', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppsPage())),
    );

    expect(find.text('Download Center'), findsOneWidget);
    expect(find.text('Scoreboard Online'), findsOneWidget);
    expect(find.text('Arisan Online'), findsOneWidget);
    expect(find.text('LED Signboard'), findsOneWidget);
    expect(find.text('Download APK (v1.0.0)'), findsWidgets);
  });
}

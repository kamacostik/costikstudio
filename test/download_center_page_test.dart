import 'package:costikstudio/features/apps/view/apps_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders download center page with focused downloadable apps', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppsPage())),
    );

    expect(find.text('Download Center'), findsOneWidget);
    expect(find.text('Smart INV'), findsOneWidget);
    expect(find.text('Scoreboard Online'), findsNothing);
    expect(find.text('Arisan Online'), findsNothing);
    expect(find.text('LED Signboard'), findsNothing);
    expect(find.text('Download APK (v1.0.0)'), findsWidgets);
  });
}

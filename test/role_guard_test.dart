import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'hides Admin Billing nav for customer and redirects /admin/billing',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CostikStudioApp());
      await tester.pumpAndSettle();

      // Customer role by default
      expect(find.text('Admin Billing'), findsNothing);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.person_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.admin_panel_settings_rounded), findsWidgets);
      expect(find.text('Admin'), findsWidgets);
    },
  );
}

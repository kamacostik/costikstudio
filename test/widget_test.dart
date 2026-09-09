import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'CostikStudio app renders long landing page with focused products',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const CostikStudioApp());
      await tester.pumpAndSettle();

      expect(find.text('CostikStudio'), findsWidgets);
      expect(
        find.text('Launch business apps from one clean studio.'),
        findsOneWidget,
      );
      expect(find.text('Open Billing'), findsOneWidget);
      expect(find.text('View Products'), findsOneWidget);
      expect(
        find.text('FOCUSED PRODUCTS', skipOffstage: false),
        findsOneWidget,
      );
      expect(find.text('Costik IPTV', skipOffstage: false), findsOneWidget);
      expect(find.text('Digital Signage', skipOffstage: false), findsOneWidget);
      expect(find.text('CosHRIS', skipOffstage: false), findsOneWidget);
      expect(find.text('Smart INV', skipOffstage: false), findsOneWidget);
      expect(find.text('CosPOS Coffee Shop'), findsNothing);
      expect(find.text('Scoreboard Online'), findsNothing);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1100),
      );
      await tester.pumpAndSettle();

      expect(find.text('Quick Links'), findsOneWidget);
      expect(find.text('Legal'), findsOneWidget);
      expect(find.text('support@costikstudio.com'), findsOneWidget);
      expect(
        find.text(
          '© 2026 CostikStudio - Costik Digital Solutions. All rights reserved.',
        ),
        findsOneWidget,
      );
    },
  );
}

import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CostikStudio app renders minimal landing page', (tester) async {
    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    expect(find.text('CostikStudio'), findsWidgets);
    expect(
      find.text('Launch business apps from one clean studio.'),
      findsOneWidget,
    );
    expect(find.text('Open Billing'), findsOneWidget);
    expect(find.text('View Products'), findsOneWidget);
    expect(find.text('Billing wallet'), findsOneWidget);
    expect(find.text('App downloads'), findsOneWidget);
    expect(find.text('Product hub'), findsOneWidget);
  });
}

import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CostikStudio app renders landing page', (tester) async {
    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    expect(find.text('CostikStudio'), findsWidgets);
    expect(find.text('Explore products'), findsOneWidget);
    expect(find.text('Download apps'), findsOneWidget);
  });
}

import 'package:costikstudio/features/support/data/feature_request_repository.dart';
import 'package:costikstudio/features/support/view/support_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('feature request form submits selected product to repository', (
    tester,
  ) async {
    final repository = _FakeFeatureRequestRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SupportPage(
            mode: SupportPageMode.featureRequest,
            repository: repository,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('feature_request_product_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Smart INV').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('feature_request_title_field')),
      'Export Excel',
    );
    await tester.enterText(
      find.byKey(const Key('feature_request_detail_field')),
      'Butuh export data transaksi ke Excel.',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Kirim Request'));
    await tester.pumpAndSettle();

    expect(repository.submitted.single.productId, 'smart-inv');
    expect(repository.submitted.single.productName, 'Smart INV');
    expect(repository.submitted.single.title, 'Export Excel');
    expect(find.text('Request fitur berhasil dikirim.'), findsOneWidget);
  });
}

class _FakeFeatureRequestRepository implements FeatureRequestRepository {
  final submitted = <FeatureRequestDraft>[];

  @override
  Future<void> submit(FeatureRequestDraft draft) async {
    submitted.add(draft);
  }
}

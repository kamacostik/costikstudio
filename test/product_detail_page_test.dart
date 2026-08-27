import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/features/product_detail/view/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders product detail page with product info and features', (
    tester,
  ) async {
    final product = findProductById('cospos');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductDetailPage(product: product)),
      ),
    );

    expect(find.text('CosPOS Coffee Shop'), findsOneWidget);
    expect(find.text('Key features'), findsOneWidget);
    expect(
      find.text('Built-in Chat Support for mobile & web admin'),
      findsOneWidget,
    );
  });

  testWidgets('renders scoreboard online detail page', (tester) async {
    final product = findProductById('scoreboard-online');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductDetailPage(product: product)),
      ),
    );

    expect(find.text('Scoreboard Online'), findsOneWidget);
    expect(
      find.text('Remove Ads Lifetime in-app purchase integration'),
      findsOneWidget,
    );
  });
}

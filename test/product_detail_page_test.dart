import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/features/product_detail/view/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders IPTV product detail page with product info and features',
    (tester) async {
      final product = findProductById('costik-iptv');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProductDetailPage(product: product)),
        ),
      );

      expect(find.text('Costik IPTV'), findsOneWidget);
      expect(find.text('Key features'), findsOneWidget);
      expect(
        find.text('Live TV and guest room entertainment flow'),
        findsOneWidget,
      );
      expect(find.text('Berlangganan sekarang'), findsOneWidget);
    },
  );

  testWidgets('renders smart inventory detail page', (tester) async {
    final product = findProductById('smart-inv');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductDetailPage(product: product)),
      ),
    );

    expect(find.text('Smart INV'), findsOneWidget);
    expect(find.text('Product and stock movement tracking'), findsOneWidget);
  });
}

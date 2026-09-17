import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/shared/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IPTV product card exposes demo login information', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    const product = ProductItem(
      id: 'costik-iptv',
      name: 'Costik IPTV',
      tagline: 'Hotel IPTV system',
      description: 'IPTV platform',
      category: ProductCategory.hospitality,
      status: ProductStatus.beta,
      accentHex: 0xFF0EA5E9,
      features: ['Live TV'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProductCard(product: product)),
      ),
    );

    expect(find.text('Demo'), findsOneWidget);

    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();

    expect(find.text('Demo Admin IPTV'), findsOneWidget);
    expect(find.text('demo1@costikstudio.com'), findsOneWidget);
    expect(find.text('demo112233'), findsOneWidget);
  });
}

import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/shared/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('product card shows cover image and gallery count', (
    tester,
  ) async {
    const product = ProductItem(
      id: 'costik-iptv',
      name: 'Costik IPTV',
      tagline: 'Hotel IPTV system',
      description: 'IPTV platform',
      category: ProductCategory.hospitality,
      status: ProductStatus.beta,
      accentHex: 0xFF0EA5E9,
      features: ['Live TV'],
      images: [
        ProductImage(
          id: 'img-1',
          productId: 'costik-iptv',
          imageUrl: 'https://example.com/iptv-cover.png',
          title: 'Dashboard preview',
          isCover: true,
        ),
        ProductImage(
          id: 'img-2',
          productId: 'costik-iptv',
          imageUrl: 'https://example.com/iptv-player.png',
          title: 'Player preview',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ProductCard(product: product)),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('2 images'), findsOneWidget);
    expect(find.text('Dashboard preview'), findsOneWidget);
  });
}

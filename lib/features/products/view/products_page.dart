import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/features/shared/widgets/product_card.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ResponsiveSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Products',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Dummy catalog for CostikStudio products, admin portals, and active project access points.',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: const Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              itemCount: dummyProducts.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 380,
                mainAxisExtent: 350,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              itemBuilder: (context, index) =>
                  ProductCard(product: dummyProducts[index]),
            ),
          ],
        ),
      ),
    );
  }
}

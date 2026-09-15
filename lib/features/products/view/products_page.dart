import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/data/product_gallery_loader.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/shared/widgets/product_card.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    this.galleryLoader = const ProductGalleryLoader(),
  });

  final ProductGalleryLoader galleryLoader;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final Future<List<ProductItem>> _productsFuture = widget.galleryLoader
      .attachImages(dummyProducts);

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
            FutureBuilder<List<ProductItem>>(
              future: _productsFuture,
              initialData: dummyProducts,
              builder: (context, snapshot) {
                final products = snapshot.data ?? dummyProducts;
                return GridView.builder(
                  itemCount: products.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 350,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemBuilder: (context, index) =>
                      ProductCard(product: products[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

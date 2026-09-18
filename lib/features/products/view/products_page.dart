import 'package:costikstudio/features/products/cubit/product_catalog_cubit.dart';
import 'package:costikstudio/features/shared/widgets/product_card.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  bool _loadRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadRequested) return;
    _loadRequested = true;
    context.read<ProductCatalogCubit>().load();
  }

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
            BlocBuilder<ProductCatalogCubit, ProductCatalogState>(
              builder: (context, state) {
                final products = state.products;
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

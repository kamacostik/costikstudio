import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/shared/widgets/product_card.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';

class AppsPage extends StatelessWidget {
  const AppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final apps = dummyProducts
        .where((product) => product.isFree || product.hasDownload)
        .toList();

    return SingleChildScrollView(
      child: ResponsiveSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apps & Downloads',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'A dummy download hub for free apps, public APK links, changelogs, and privacy pages.',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: const Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            GridView.builder(
              itemCount: apps.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 380,
                mainAxisExtent: 320,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              itemBuilder: (context, index) => ProductCard(
                product: apps[index],
                compact: apps[index].category != ProductCategory.freeApp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

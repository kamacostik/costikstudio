import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductItem? product;

  @override
  Widget build(BuildContext context) {
    final item = product;
    if (item == null) {
      return ResponsiveSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product not found',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/products'),
              child: const Text('Back to products'),
            ),
          ],
        ),
      );
    }

    final accent = Color(item.accentHex);

    return SingleChildScrollView(
      child: ResponsiveSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/products'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to products'),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(34),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      item.status.name.toUpperCase(),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: CostikStudioTheme.slate, height: 1.6),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (item.hasAdmin)
                        FilledButton.icon(
                          onPressed: () => context.go('/support'),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Open web admin'),
                        ),
                      FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.billing),
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: const Text('Berlangganan sekarang'),
                      ),
                      if (item.hasDownload)
                        OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutes.apps),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download app'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Key features',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (final feature in item.features)
              Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle_rounded, color: accent),
                  title: Text(feature),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

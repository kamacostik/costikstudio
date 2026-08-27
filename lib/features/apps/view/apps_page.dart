import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppsPage extends StatelessWidget {
  const AppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadableProducts = dummyProducts
        .where((product) => product.hasDownload || product.isFree)
        .toList();

    return SingleChildScrollView(
      child: ResponsiveSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CostikStudioTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.download_for_offline_rounded,
                    color: CostikStudioTheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download Center',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Official APK builds, Play Store badges, and direct links for CostikStudio mobile apps.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: CostikStudioTheme.slate,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            for (final item in downloadableProducts) ...[
              _DownloadCard(item: item),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadCard extends StatelessWidget {
  const _DownloadCard({required this.item});

  final ProductItem item;

  @override
  Widget build(BuildContext context) {
    final accent = Color(item.accentHex);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.android_rounded, color: accent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      item.tagline,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: CostikStudioTheme.slate),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: CostikStudioTheme.slate, height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.go('/products/${item.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.info_outline_rounded, size: 18),
                label: const Text('View Details'),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download APK (v1.0.0)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

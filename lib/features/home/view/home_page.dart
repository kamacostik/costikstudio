import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/features/shared/widgets/product_card.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final featuredProducts = dummyProducts.take(3).toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          ResponsiveSection(
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 48),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 860;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: isWide ? 6 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _HeroBadge(),
                          const SizedBox(height: 24),
                          Text(
                            'Build, launch, and manage Costik digital products from one studio.',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: -1.2,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'CostikStudio is the central portal for CosPOS, IPTV, business tools, and free apps created by Kamaruddin.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: CostikStudioTheme.slate,
                                  height: 1.6,
                                ),
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: () => context.go('/products'),
                                icon: const Icon(Icons.grid_view_rounded),
                                label: const Text('Explore products'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => context.go('/apps'),
                                icon: const Icon(Icons.download_rounded),
                                label: const Text('Download apps'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isWide)
                      const SizedBox(width: 48)
                    else
                      const SizedBox(height: 36),
                    Expanded(
                      flex: isWide ? 4 : 0,
                      child: const _PortalPreviewCard(),
                    ),
                  ],
                );
              },
            ),
          ),
          ResponsiveSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Featured products',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  itemCount: featuredProducts.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 330,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemBuilder: (context, index) =>
                      ProductCard(product: featuredProducts[index]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: CostikStudioTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'CostikStudio Product Portal',
        style: TextStyle(
          color: CostikStudioTheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PortalPreviewCard extends StatelessWidget {
  const _PortalPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.hub_rounded, color: Colors.white, size: 42),
            const SizedBox(height: 26),
            Text(
              'One brand, many products.',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Text(
              'Use CostikStudio as the launchpad for web admins, product pages, documentation, downloads, and support.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            const _PreviewLine(label: 'Portal', value: 'costikstudio.com'),
            const _PreviewLine(
              label: 'CosPOS Admin',
              value: 'admin.cospos.costikstudio.com',
            ),
            const _PreviewLine(
              label: 'IPTV Admin',
              value: 'admin.iptv.costikstudio.com',
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.58)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

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
                            'One studio for apps, web admins, and digital products.',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.04,
                                  letterSpacing: -1.4,
                                  color: CostikStudioTheme.navy,
                                ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'CostikStudio is the official product hub for CosPOS, IPTV, business tools, and downloadable apps built for real users and client operations.',
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
          const ResponsiveSection(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: _StatsStrip(),
          ),
          ResponsiveSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Featured products',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.go('/products'),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                GridView.builder(
                  itemCount: featuredProducts.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 420,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 18,
                  ),
                  itemBuilder: (context, index) =>
                      ProductCard(product: featuredProducts[index]),
                ),
              ],
            ),
          ),
          ResponsiveSection(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 80),
            child: _LaunchpadSection(
              onProductsTap: () => context.go('/products'),
              onAppsTap: () => context.go('/apps'),
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
        border: Border.all(
          color: CostikStudioTheme.primary.withValues(alpha: 0.18),
        ),
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

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Wrap(
          spacing: 34,
          runSpacing: 18,
          alignment: WrapAlignment.spaceBetween,
          children: const [
            _StatItem(value: '7+', label: 'Projects listed'),
            _StatItem(value: '3', label: 'Web admin portals'),
            _StatItem(value: '4+', label: 'Downloadable apps'),
            _StatItem(value: 'Cloudflare', label: 'Pages-ready portal'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: CostikStudioTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: CostikStudioTheme.slate,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
            colors: [Color(0xFF061B31), Color(0xFF533AFD), Color(0xFF0EA5E9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF32325D).withValues(alpha: 0.25),
              blurRadius: 45,
              offset: const Offset(0, 30),
              spreadRadius: -30,
            ),
          ],
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

class _LaunchpadSection extends StatelessWidget {
  const _LaunchpadSection({
    required this.onProductsTap,
    required this.onAppsTap,
  });

  final VoidCallback onProductsTap;
  final VoidCallback onAppsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: CostikStudioTheme.navy,
        borderRadius: BorderRadius.circular(28),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 760;
          return Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: isWide ? 6 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready for subdomains, downloads, and product access.',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This first version keeps the portal static and clean, so Cloudflare Pages can deploy it quickly before we connect live product data later.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              if (isWide)
                const SizedBox(width: 24)
              else
                const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    onPressed: onProductsTap,
                    child: const Text('Manage products'),
                  ),
                  OutlinedButton(
                    onPressed: onAppsTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View downloads'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

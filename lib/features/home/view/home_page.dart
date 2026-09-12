import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/core/router/app_router.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static void scrollToProducts() => _HomePageState.scrollToProducts();

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static final _productsKey = GlobalKey();

  static void scrollToProducts() {
    final context = _productsKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  List<ProductItem> get _focusProducts => dummyProducts
      .where(
        (product) => const {
          'costik-iptv',
          'digital-signage',
          'coshris',
          'smart-inv',
        }.contains(product.id),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthCubit>().state.isAuthenticated;

    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 86, 24, 96),
                child: Column(
                  children: [
                    const _HeroBadge(),
                    const SizedBox(height: 28),
                    Text(
                      'Launch business apps from one clean studio.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(
                            color: CostikStudioTheme.navy,
                            fontWeight: FontWeight.w900,
                            height: 1.04,
                            letterSpacing: -1.6,
                          ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 690),
                      child: Text(
                        'CostikStudio brings all your business applications into a single central portal for IPTV, Digital Signage, CosHRIS, and Smart INV.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: CostikStudioTheme.slate,
                              height: 1.65,
                            ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () => context.go(
                            isAuthenticated
                                ? AppRoutes.billing
                                : AppRoutes.login,
                          ),
                          icon: Icon(
                            isAuthenticated
                                ? Icons.dashboard_rounded
                                : Icons.login_rounded,
                          ),
                          label: Text(isAuthenticated ? 'Dashboard' : 'Login'),
                        ),
                        OutlinedButton.icon(
                          onPressed: HomePage.scrollToProducts,
                          icon: const Icon(Icons.apps_rounded),
                          label: const Text('View Products'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 54),
                    const _MinimalPortalPreview(),
                    const SizedBox(height: 92),
                    _ProductSection(
                      key: _productsKey,
                      products: _focusProducts,
                    ),
                    const SizedBox(height: 92),
                    const _HowItWorksSection(),
                  ],
                ),
              ),
            ),
          ),
          const SiteFooter(),
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
        color: CostikStudioTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: CostikStudioTheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: const Text(
        'CostikStudio Portal',
        style: TextStyle(
          color: CostikStudioTheme.primary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _MinimalPortalPreview extends StatelessWidget {
  const _MinimalPortalPreview();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 34,
              offset: const Offset(0, 22),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 720;
            final items = const [
              _PreviewItem(
                icon: Icons.hub_rounded,
                title: 'Central Access',
                description: 'A single portal gate to access and launch all your Costik products.',
              ),
              _PreviewItem(
                icon: Icons.grid_view_rounded,
                title: 'Integrated Ecosystem',
                description: 'Unified solutions for IPTV, Digital Signage, HRIS, and Smart INV.',
              ),
              _PreviewItem(
                icon: Icons.devices_rounded,
                title: 'Cloud & Multi-Platform',
                description: 'Seamlessly managed from cloud across web, mobile, TV, and desktop.',
              ),
            ];

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final item in items)
                  SizedBox(
                    width: isWide
                        ? (constraints.maxWidth - 32) / 3
                        : double.infinity,
                    child: item,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({super.key, required this.products});

  final List<ProductItem> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionLabel(label: 'Focused Products'),
        const SizedBox(height: 14),
        Text(
          'Four core products for business operations.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: CostikStudioTheme.navy,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Start from the product you need: hospitality TV, digital display, HR operations, or inventory management.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: CostikStudioTheme.slate, height: 1.6),
          ),
        ),
        const SizedBox(height: 34),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 780;
            return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: [
                for (final product in products)
                  SizedBox(
                    width: isWide
                        ? (constraints.maxWidth - 18) / 2
                        : double.infinity,
                    child: _FocusProductCard(product: product),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FocusProductCard extends StatelessWidget {
  const _FocusProductCard({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final accent = Color(product.accentHex);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.go('/products/${product.id}'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(product.id), color: accent, size: 26),
              ),
              const SizedBox(height: 20),
              Text(
                product.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: CostikStudioTheme.navy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.tagline,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: CostikStudioTheme.slate, height: 1.55),
              ),
              const SizedBox(height: 18),
              Text(
                'View details',
                style: TextStyle(color: accent, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String id) {
    return switch (id) {
      'costik-iptv' => Icons.tv_rounded,
      'digital-signage' => Icons.screenshot_monitor_rounded,
      'coshris' => Icons.groups_rounded,
      'smart-inv' => Icons.inventory_2_rounded,
      _ => Icons.apps_rounded,
    };
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: CostikStudioTheme.navy,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Wrap(
        spacing: 26,
        runSpacing: 20,
        alignment: WrapAlignment.spaceBetween,
        children: const [
          _DarkStep(number: '01', title: 'Choose product'),
          _DarkStep(number: '02', title: 'Top up wallet'),
          _DarkStep(number: '03', title: 'Activate subscription'),
        ],
      ),
    );
  }
}

class _DarkStep extends StatelessWidget {
  const _DarkStep({required this.number, required this.title});

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Row(
        children: [
          Text(
            number,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: CostikStudioTheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CostikStudioTheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CostikStudioTheme.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: CostikStudioTheme.primary, size: 22),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: CostikStudioTheme.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: CostikStudioTheme.slate, height: 1.5),
          ),
        ],
      ),
    );
  }
}

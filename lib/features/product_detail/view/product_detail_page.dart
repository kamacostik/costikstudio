import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductItem? product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  @override
  Widget build(BuildContext context) {
    final item = widget.product;
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
    final isAuthenticated = context.select<AuthCubit, bool>(
      (cubit) => cubit.state.isAuthenticated,
    );

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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusPill(
                        label: item.status.name.toUpperCase(),
                        color: accent,
                      ),
                      _StatusPill(
                        label: item.isFree ? 'FREE APP' : 'SAAS PRODUCT',
                        color: item.isFree
                            ? Colors.green
                            : CostikStudioTheme.primary,
                      ),
                      _StatusPill(
                        label: item.category.name.toUpperCase(),
                        color: Colors.indigo,
                      ),
                    ],
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
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (isAuthenticated) ...[
                        FilledButton.icon(
                          onPressed: () {
                            if (item.id == 'costik-iptv') {
                              context.go(AppRoutes.subscribeIptv);
                            } else {
                              context.go(AppRoutes.billing);
                            }
                          },
                          icon: const Icon(Icons.workspace_premium_rounded),
                          label: Text(
                            item.isFree
                                ? 'Buka dari Apps'
                                : 'Berlangganan sekarang',
                          ),
                        ),
                        if (item.hasAdmin)
                          OutlinedButton.icon(
                            onPressed: () => context.go('/support'),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Info web admin'),
                          ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.login),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Login untuk berlangganan'),
                        ),
                      ],

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
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: item.features
                  .map(
                    (feature) => SizedBox(
                      width: 360,
                      child: _FeatureTile(feature: feature, color: accent),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature, required this.color});

  final String feature;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.check_circle_rounded, color: color),
        title: Text(
          feature,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/core/platform/external_url.dart';
import 'package:costikstudio/features/products/cubit/product_catalog_cubit.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/shared/widgets/product_gallery_strip.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductItem? product;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductCatalogCubit, ProductCatalogState>(
      builder: (context, state) {
        final item = product == null ? null : state.productById(product!.id);
        return _DetailBody(item: item ?? product);
      },
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.item});

  final ProductItem? item;

  @override
  Widget build(BuildContext context) {
    final detail = this.item;
    if (detail == null) {
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

    final item = detail;
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
                  if (item.activeImages.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    ProductGalleryStrip(images: item.activeImages),
                  ],
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
                            } else if (item.id == 'digital-signage') {
                              context.go(AppRoutes.subscribeSignage);
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
                        if (item.id == 'costik-iptv')
                          OutlinedButton.icon(
                            onPressed: () => _showIptvDemoDialog(context),
                            icon: const Icon(Icons.play_circle_outline_rounded),
                            label: const Text('Demo'),
                          ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showMemberDocumentation(context, item),
                          icon: const Icon(Icons.menu_book_rounded),
                          label: const Text('Lihat Dokumentasi'),
                        ),
                        if (item.hasAdmin)
                          OutlinedButton.icon(
                            onPressed: () => openExternalUrl(item.adminUrl!),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Open web admin'),
                          ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.login),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Login untuk berlangganan'),
                        ),
                      ],
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

  void _showIptvDemoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo Admin IPTV',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Akses demo dashboard web admin',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gunakan akun demo ini untuk mencoba dashboard Admin IPTV tanpa mengubah data hotel Anda.',
              style: TextStyle(color: CostikStudioTheme.slate, height: 1.5),
            ),
            SizedBox(height: 18),
            _DemoCredentialTile(
              icon: Icons.alternate_email_rounded,
              label: 'User',
              value: 'demo1@costikstudio.com',
            ),
            SizedBox(height: 10),
            _DemoCredentialTile(
              icon: Icons.lock_rounded,
              label: 'Password',
              value: 'demo112233',
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Tutup'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              openExternalUrl('https://admin-ip-tv.pages.dev/');
            },
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('Open Admin IPTV'),
          ),
        ],
      ),
    );
  }

  void _showMemberDocumentation(BuildContext context, ProductItem item) {
    final steps = <(String, String)>[
      (
        'Berlangganan dari CostikStudio',
        'Login ke CostikStudio, pilih paket IPTV, lalu aktifkan subscription sesuai jumlah device hotel.',
      ),
      (
        'Buat password Admin IPTV',
        'Setelah subscription aktif, buka dashboard billing lalu buat password Admin IPTV untuk login email/password.',
      ),
      (
        'Login ke web admin',
        'Buka web admin, kelola menu hotel, channel TV, device, konten, dan carousel Hotel Info.',
      ),
      (
        'Install APK IPTV',
        'Download APK, pasang di device/TV, lalu pairing dengan akun admin hotel.',
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.92,
        minChildSize: 0.45,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Dokumentasi ${item.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: CostikStudioTheme.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Panduan cepat untuk mencoba demo, aktivasi subscription, dan membuka web admin.',
                style: TextStyle(color: CostikStudioTheme.slate, height: 1.5),
              ),
              const SizedBox(height: 18),
              for (var i = 0; i < steps.length; i++)
                _DocStep(
                  number: i + 1,
                  title: steps[i].$1,
                  content: steps[i].$2,
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Tutup Dokumentasi'),
              ),
            ],
          ),
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

class _DemoCredentialTile extends StatelessWidget {
  const _DemoCredentialTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: CostikStudioTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: CostikStudioTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: CostikStudioTheme.slate,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: const TextStyle(
                    color: CostikStudioTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocStep extends StatelessWidget {
  const _DocStep({
    required this.number,
    required this.title,
    required this.content,
  });

  final int number;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: CostikStudioTheme.primary.withValues(alpha: 0.12),
            child: Text(
              '$number',
              style: const TextStyle(
                color: CostikStudioTheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CostikStudioTheme.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: CostikStudioTheme.slate,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
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

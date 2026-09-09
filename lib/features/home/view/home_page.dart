import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
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
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
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
                    'CostikStudio brings billing, downloads, and product access into a simple portal for tools like CosPOS, Signage, IPTV, and HRIS.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      onPressed: () => context.go('/billing'),
                      icon: const Icon(Icons.account_balance_wallet_rounded),
                      label: const Text('Open Billing'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/products'),
                      icon: const Icon(Icons.apps_rounded),
                      label: const Text('View Products'),
                    ),
                  ],
                ),
                const SizedBox(height: 54),
                const _MinimalPortalPreview(),
              ],
            ),
          ),
        ),
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
                icon: Icons.wallet_rounded,
                title: 'Billing wallet',
                description: 'Top-up and subscription flow for customers.',
              ),
              _PreviewItem(
                icon: Icons.cloud_download_rounded,
                title: 'App downloads',
                description: 'Central place for installers and app files.',
              ),
              _PreviewItem(
                icon: Icons.dashboard_customize_rounded,
                title: 'Product hub',
                description: 'Short paths to active Costik products.',
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

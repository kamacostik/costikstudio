import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/billing/admin/admin_billing_cubit.dart';
import 'package:costikstudio/features/billing/admin/dummy_admin_billing_repository.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Admin landing dashboard (dummy-first).
///
/// Aggregates headline metrics from the dummy admin billing snapshot and
/// routes into each backoffice module. Real Supabase aggregates replace the
/// dummy repository later without changing this page.
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminBillingCubit(repository: DummyAdminBillingRepository())..load(),
      child: const _AdminDashboardView(),
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBillingCubit, AdminBillingState>(
      builder: (context, state) {
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final pendingTopUps = snapshot.pendingTopUps.length;
        final activeSubs = snapshot.subscriptionMetrics
            .where((m) => m.label == 'Active Subscriptions')
            .map((m) => m.value)
            .firstOrNull ?? '-';
        final totalDevices = snapshot.subscriptionMetrics
            .where((m) => m.label == 'Total Devices Monitored')
            .map((m) => m.value)
            .firstOrNull ?? '-';
        final totalCustomers = snapshot.customerWallets.length;

        return SingleChildScrollView(
          child: ResponsiveSection(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ringkasan Admin',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pantau billing, subscription, dan tenant Signage dari satu dashboard.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CostikStudioTheme.slate,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    final metrics = [
                      _MetricTile(
                        icon: Icons.pending_actions_rounded,
                        label: 'Top Up Pending',
                        value: '$pendingTopUps',
                      ),
                      _MetricTile(
                        icon: Icons.people_rounded,
                        label: 'Customer Terdaftar',
                        value: '$totalCustomers',
                      ),
                      _MetricTile(
                        icon: Icons.verified_user_rounded,
                        label: 'Subscription Aktif',
                        value: activeSubs,
                      ),
                      _MetricTile(
                        icon: Icons.devices_other_rounded,
                        label: 'Device Dimonitor',
                        value: totalDevices,
                      ),
                    ];
                    if (!isWide) {
                      return Column(
                        children: [
                          for (final m in metrics) ...[
                            m,
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (var i = 0; i < metrics.length; i++) ...[
                          Expanded(child: metrics[i]),
                          if (i < metrics.length - 1)
                            const SizedBox(width: 12),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _ModuleCard(
                  icon: Icons.receipt_long_rounded,
                  title: 'Billing & Subscription',
                  description:
                      'Setujui top up manual, pantau wallet customer, dan kelola subscription IPTV.',
                  ctaLabel: 'Buka Billing',
                  onTap: () => context.go(AppRoutes.adminBilling),
                ),
                const SizedBox(height: 12),
                _ModuleCard(
                  icon: Icons.tv_rounded,
                  title: 'Signage Tenants',
                  description:
                      'Daftar tenant/hotel Signage customer beserta status device dan subscription.',
                  ctaLabel: 'Buka Signage',
                  onTap: () => context.go(AppRoutes.adminSignage),
                ),
                const SizedBox(height: 12),
                _ModuleCard(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Akun Admin',
                  description: 'Profil dan sesi akun administrator.',
                  ctaLabel: 'Buka Akun',
                  onTap: () => context.go(AppRoutes.account),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: CostikStudioTheme.primary, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: CostikStudioTheme.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CostikStudioTheme.slate,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: CostikStudioTheme.primary.withValues(alpha: 0.10),
              foregroundColor: CostikStudioTheme.primary,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: CostikStudioTheme.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: CostikStudioTheme.slate,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(onPressed: onTap, child: Text(ctaLabel)),
          ],
        ),
      ),
    );
  }
}

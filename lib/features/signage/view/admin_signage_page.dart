import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:costikstudio/features/signage/admin/admin_signage_cubit.dart';
import 'package:costikstudio/features/signage/admin/admin_signage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Admin-only tenant overview for Signage.
///
/// Dummy-first: shows seeded tenants until Supabase RPC
/// `admin_list_signage_tenants` is applied. Never edits tenant content —
/// content stays in the per-tenant Signage admin flow.
class AdminSignagePage extends StatelessWidget {
  const AdminSignagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminSignageCubit()..load(),
      child: const _AdminSignageView(),
    );
  }
}

class _AdminSignageView extends StatelessWidget {
  const _AdminSignageView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSignageCubit, AdminSignageState>(
      builder: (context, state) {
        if (state.status == AdminSignageStatus.loading &&
            state.tenants.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: ResponsiveSection(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signage Tenants',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Daftar tenant/hotel Signage customer beserta status subscription dan device.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: CostikStudioTheme.slate,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                if (state.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (state.tenants.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada tenant Signage.'),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 900;
                      final cards = [
                        for (final tenant in state.tenants)
                          _TenantCard(tenant: tenant),
                      ];
                      if (!isWide) {
                        return Column(
                          children: [
                            for (final card in cards) ...[
                              card,
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.9,
                        children: cards,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({required this.tenant});

  final AdminSignageTenant tenant;

  @override
  Widget build(BuildContext context) {
    final status = tenant.subscriptionStatus ?? 'unknown';
    final isActive = status == 'active';
    final expiry = tenant.subscriptionExpiresAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tenant.tenantName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tenant.customerEmail ?? tenant.customerName,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Device aktif ${tenant.deviceActive}/${tenant.deviceTotal}'
              '${tenant.subscriptionDeviceCount != null ? ' • kuota ${tenant.subscriptionDeviceCount}' : ''}'
              '${expiry != null ? ' • expired ${expiry.day}/${expiry.month}/${expiry.year}' : ''}',
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

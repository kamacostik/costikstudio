import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:costikstudio/features/signage/admin/admin_signage_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:costikstudio/features/signage/view/widgets/signage_table_widgets.dart';

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
            maxWidth: double.infinity,
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
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: CostikStudioTheme.slate, height: 1.5),
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
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SignageDataTable(
                        emptyIcon: Icons.business_rounded,
                        emptyMessage: 'Belum ada tenant Signage',
                        columns: [
                          signageDataColumn('Tenant (Hotel)'),
                          signageDataColumn('Owner / Pelanggan'),
                          signageDataColumn('Kuota Dev'),
                          signageDataColumn('Device Terpakai'),
                          signageDataColumn('Expired'),
                          signageDataColumn('Status'),
                        ],
                        rows: [
                          for (final tenant in state.tenants)
                            DataRow(
                              cells: [
                                DataCell(
                                  SignageReferenceCell(
                                    icon: Icons.business_rounded,
                                    iconColor: Colors.blue,
                                    title: tenant.tenantName,
                                    reference:
                                        'ID: ${tenant.tenantId.length > 8 ? tenant.tenantId.substring(0, 8) : tenant.tenantId}',
                                  ),
                                ),
                                DataCell(
                                  SignageReferenceCell(
                                    icon: Icons.person_rounded,
                                    iconColor: Colors.deepPurple,
                                    title: tenant.customerName.isNotEmpty
                                        ? tenant.customerName
                                        : 'Unknown',
                                    reference: tenant.customerEmail ?? '-',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    tenant.subscriptionDeviceCount
                                            ?.toString() ??
                                        '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${tenant.deviceActive}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: tenant.deviceActive > 0
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        ' / ${tenant.deviceTotal} total',
                                        style: const TextStyle(
                                          color: CostikStudioTheme.slate,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    tenant.subscriptionExpiresAt != null
                                        ? '${tenant.subscriptionExpiresAt!.day}/${tenant.subscriptionExpiresAt!.month}/${tenant.subscriptionExpiresAt!.year}'
                                        : '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SignageStatusBadge(
                                    label:
                                        (tenant.subscriptionStatus ?? 'unknown')
                                            .toUpperCase(),
                                    color: tenant.subscriptionStatus == 'active'
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

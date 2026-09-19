import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:costikstudio/features/billing/admin/admin_billing_cubit.dart';
import 'package:costikstudio/features/billing/admin/admin_billing_repository.dart';
import 'package:costikstudio/features/billing/admin/dummy_admin_billing_repository.dart';
import 'package:costikstudio/features/billing/admin/supabase_admin_billing_repository.dart';
import 'package:costikstudio/features/billing/widgets/billing_notice.dart';
import 'package:costikstudio/features/signage/view/widgets/signage_table_widgets.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminBillingPage extends StatelessWidget {
  const AdminBillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBillingCubit(
        repository: SupabaseConfig.isConfigured
            ? const SupabaseAdminBillingRepository()
            : DummyAdminBillingRepository(),
      )..load(),
      child: const _AdminBillingView(),
    );
  }
}

class _AdminBillingView extends StatelessWidget {
  const _AdminBillingView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBillingCubit, AdminBillingState>(
      builder: (context, state) {
        final snapshot = state.snapshot;
        if (snapshot == null) {
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
                  'Admin Billing',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dummy backoffice for approving manual top ups, checking customer wallets, and monitoring subscriptions.',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: CostikStudioTheme.slate, height: 1.5),
                ),
                const SizedBox(height: 28),
                if (snapshot.message != null) ...[
                  BillingNotice(message: snapshot.message!),
                  const SizedBox(height: 18),
                ],
                _AdminBillingTables(snapshot: snapshot),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminBillingTables extends StatefulWidget {
  const _AdminBillingTables({required this.snapshot});
  final AdminBillingSnapshot snapshot;

  @override
  State<_AdminBillingTables> createState() => _AdminBillingTablesState();
}

class _AdminBillingTablesState extends State<_AdminBillingTables> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SignageTableTabBar(
          children: [
            SignageTableTab(
              label: 'Riwayat Top Up',
              icon: Icons.account_balance_wallet_rounded,
              count: widget.snapshot.pendingTopUps.length,
              isSelected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            SignageTableTab(
              label: 'Saldo Customer',
              icon: Icons.people_alt_rounded,
              count: widget.snapshot.customerWallets.length,
              isSelected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
            SignageTableTab(
              label: 'Lisensi Langganan',
              icon: Icons.verified_user_rounded,
              count: widget.snapshot.allSubscriptions.length,
              isSelected: _tabIndex == 2,
              onTap: () => setState(() => _tabIndex = 2),
            ),
          ],
        ),
        const SizedBox(height: 18),
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
            child: _buildActiveTab(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTab(BuildContext context) {
    switch (_tabIndex) {
      case 0:
        return _buildTopUpsTable(context);
      case 1:
        return _buildWalletsTable(context);
      case 2:
        return _buildSubscriptionsTable(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildTopUpsTable(BuildContext context) {
    return SignageDataTable(
      emptyIcon: Icons.account_balance_wallet_rounded,
      emptyMessage: 'Belum ada riwayat top up',
      columns: [
        signageDataColumn('Pelanggan'),
        signageDataColumn('Nominal'),
        signageDataColumn('Status / Metode'),
        signageDataColumn('Aksi'),
      ],
      rows: [
        for (final topUp in widget.snapshot.pendingTopUps)
          DataRow(
            cells: [
              DataCell(
                SignageReferenceCell(
                  icon: Icons.person_rounded,
                  iconColor: Colors.blue,
                  title: topUp.customerName,
                  reference:
                      'ID: ${topUp.id.length > 8 ? topUp.id.substring(0, 8) : topUp.id}',
                ),
              ),
              DataCell(
                Text(
                  formatRupiah(topUp.amount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataCell(
                SignageStatusBadge(
                  label: topUp.method.toUpperCase(),
                  color: topUp.method.toLowerCase().contains('pending')
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
              DataCell(
                topUp.method.toLowerCase().contains('pending')
                    ? FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => context
                            .read<AdminBillingCubit>()
                            .approveTopUp(topUp.id),
                        child: const Text('Approve Manual'),
                      )
                    : const Text('-', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildWalletsTable(BuildContext context) {
    return SignageDataTable(
      emptyIcon: Icons.people_alt_rounded,
      emptyMessage: 'Belum ada data pelanggan',
      columns: [
        signageDataColumn('Pelanggan'),
        signageDataColumn('Saldo Saat Ini'),
      ],
      rows: [
        for (final wallet in widget.snapshot.customerWallets)
          DataRow(
            cells: [
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.business_rounded,
                      size: 18,
                      color: CostikStudioTheme.slate,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      wallet.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              DataCell(
                Text(
                  wallet.statusText,
                  style: const TextStyle(
                    color: CostikStudioTheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSubscriptionsTable(BuildContext context) {
    return SignageDataTable(
      emptyIcon: Icons.verified_user_rounded,
      emptyMessage: 'Belum ada data langganan',
      columns: [
        signageDataColumn('Pelanggan'),
        signageDataColumn('Produk'),
        signageDataColumn('Status / Expired'),
        signageDataColumn('Aksi (Manual)'),
      ],
      rows: [
        for (final sub in widget.snapshot.allSubscriptions)
          DataRow(
            cells: [
              DataCell(
                SignageReferenceCell(
                  icon: Icons.email_rounded,
                  iconColor: Colors.deepPurple,
                  title: sub.customerEmail,
                  reference:
                      'Dev: ${sub.deviceCount} | Siklus: ${sub.billingCycleMonths} bln',
                ),
              ),
              DataCell(
                Text(
                  sub.productName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              DataCell(
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SignageStatusBadge(
                      label: sub.statusText.toUpperCase(),
                      color: sub.statusText == 'active'
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Exp: ${_formatShortDate(sub.expiresAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: CostikStudioTheme.slate,
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Perpanjang Manual',
                      icon: const Icon(
                        Icons.more_time_rounded,
                        color: Colors.blue,
                      ),
                      onPressed: () => _showAdminExtendDialog(context, sub),
                    ),
                    IconButton(
                      tooltip: 'Ubah Kuota Device',
                      icon: const Icon(
                        Icons.devices_rounded,
                        color: Colors.orange,
                      ),
                      onPressed: () => _showAdminDeviceDialog(context, sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _showAdminExtendDialog(
    BuildContext context,
    AdminSubscriptionRecord sub,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Extend Subscription (${sub.customerEmail})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih durasi perpanjangan admin (manual grant):'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final months in const [1, 3, 6, 12])
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      context.read<AdminBillingCubit>().adminExtendSubscription(
                        subscriptionId: sub.id,
                        additionalMonths: months,
                      );
                    },
                    child: Text('+$months Bulan'),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showAdminDeviceDialog(
    BuildContext context,
    AdminSubscriptionRecord sub,
  ) {
    final controller = TextEditingController(text: '${sub.deviceCount}');
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Set Device Count (${sub.customerEmail})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan jumlah device lisensi baru untuk customer ini:',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Device',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final count = int.tryParse(controller.text);
              if (count != null && count > 0) {
                Navigator.of(dialogCtx).pop();
                context.read<AdminBillingCubit>().adminUpdateDevices(
                  subscriptionId: sub.id,
                  newDeviceCount: count,
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

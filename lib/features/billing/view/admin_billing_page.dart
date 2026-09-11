import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/features/billing/admin/admin_billing_cubit.dart';
import 'package:costikstudio/features/billing/admin/admin_billing_repository.dart';
import 'package:costikstudio/features/billing/admin/dummy_admin_billing_repository.dart';
import 'package:costikstudio/features/billing/widgets/billing_notice.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdminBillingPage extends StatelessWidget {
  const AdminBillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminBillingCubit(repository: DummyAdminBillingRepository())..load(),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    final cards = [
                      _PendingTopUpsCard(
                        pendingTopUps: snapshot.pendingTopUps,
                        onApprove: (id) =>
                            context.read<AdminBillingCubit>().approveTopUp(id),
                      ),
                      _CustomerWalletsCard(
                        customerWallets: snapshot.customerWallets,
                      ),
                      _SubscriptionOverviewCard(
                        metrics: snapshot.subscriptionMetrics,
                        allSubscriptions: snapshot.allSubscriptions,
                        onExtend: (subId, months) => context
                            .read<AdminBillingCubit>()
                            .adminExtendSubscription(
                              subscriptionId: subId,
                              additionalMonths: months,
                            ),
                        onUpdateDevices: (subId, count) => context
                            .read<AdminBillingCubit>()
                            .adminUpdateDevices(
                              subscriptionId: subId,
                              newDeviceCount: count,
                            ),
                      ),
                    ];

                    if (!isWide) {
                      return Column(
                        children: [
                          for (final card in cards) ...[
                            card,
                            const SizedBox(height: 18),
                          ],
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            children: [
                              cards[1],
                              const SizedBox(height: 18),
                              cards[2],
                            ],
                          ),
                        ),
                      ],
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

class _PendingTopUpsCard extends StatelessWidget {
  const _PendingTopUpsCard({
    required this.pendingTopUps,
    required this.onApprove,
  });

  final List<dynamic> pendingTopUps;
  final ValueChanged<String> onApprove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending top ups',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            if (pendingTopUps.isEmpty)
              const Text('No pending top ups')
            else
              ...pendingTopUps.map(
                (topUp) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.pending_actions_rounded,
                    color: CostikStudioTheme.amber,
                  ),
                  title: Text(topUp.customerName),
                  subtitle: Text('${topUp.method} • waiting approval'),
                  trailing: FilledButton(
                    onPressed: () => onApprove(topUp.id),
                    child: Text('Approve ${formatRupiah(topUp.amount)}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CustomerWalletsCard extends StatelessWidget {
  const _CustomerWalletsCard({required this.customerWallets});

  final List<dynamic> customerWallets;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer wallets',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...customerWallets.map(
              (wallet) => _MetricRow(
                label: wallet.customerName,
                value: wallet.statusText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionOverviewCard extends StatelessWidget {
  const _SubscriptionOverviewCard({
    required this.metrics,
    this.allSubscriptions = const [],
    this.onExtend,
    this.onUpdateDevices,
  });

  final List<dynamic> metrics;
  final List<AdminSubscriptionRecord> allSubscriptions;
  final void Function(String subId, int months)? onExtend;
  final void Function(String subId, int count)? onUpdateDevices;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription overview',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ...metrics.map(
              (metric) => _MetricRow(label: metric.label, value: metric.value),
            ),
            if (allSubscriptions.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Daftar Lisensi Customer',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              for (final sub in allSubscriptions)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sub.customerEmail,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: sub.statusText == 'active'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sub.statusText.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: sub.statusText == 'active'
                                    ? Colors.green.shade800
                                    : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${sub.productName} • ${sub.deviceCount} Devices • Expired: ${_formatShortDate(sub.expiresAt)}',
                        style: const TextStyle(
                          color: CostikStudioTheme.slate,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            onPressed: onExtend == null
                                ? null
                                : () => _showAdminExtendDialog(context, sub),
                            icon: const Icon(Icons.more_time_rounded, size: 14),
                            label: const Text('Extend Expiry'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            onPressed: onUpdateDevices == null
                                ? null
                                : () => _showAdminDeviceDialog(context, sub),
                            icon: const Icon(Icons.edit_rounded, size: 14),
                            label: const Text('Set Devices'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
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
            const Text(
              'Pilih durasi perpanjangan admin (manual grant/bypassed billing):',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final months in const [1, 3, 6, 12])
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      onExtend?.call(sub.id, months);
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
                onUpdateDevices?.call(sub.id, count);
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

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(color: CostikStudioTheme.slate)),
        ],
      ),
    );
  }
}

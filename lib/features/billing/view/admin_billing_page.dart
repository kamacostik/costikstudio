import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/features/billing/admin/admin_billing_cubit.dart';
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
  const _SubscriptionOverviewCard({required this.metrics});

  final List<dynamic> metrics;

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
          ],
        ),
      ),
    );
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
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: CostikStudioTheme.slate)),
        ],
      ),
    );
  }
}

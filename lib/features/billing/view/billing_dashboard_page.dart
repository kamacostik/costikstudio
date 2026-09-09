import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/features/billing/billing_dependencies.dart';
import 'package:costikstudio/features/billing/cubit/billing_cubit.dart';
import 'package:costikstudio/features/billing/widgets/billing_notice.dart';
import 'package:costikstudio/features/billing/widgets/invoices_card.dart';
import 'package:costikstudio/features/billing/widgets/plan_catalog_card.dart';
import 'package:costikstudio/features/billing/widgets/subscriptions_card.dart';
import 'package:costikstudio/features/billing/widgets/transactions_card.dart';
import 'package:costikstudio/features/billing/widgets/wallet_card.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BillingDashboardPage extends StatelessWidget {
  const BillingDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BillingCubit(repository: createBillingRepository())..load(),
      child: const _BillingDashboardView(),
    );
  }
}

class _BillingDashboardView extends StatefulWidget {
  const _BillingDashboardView();

  @override
  State<_BillingDashboardView> createState() => _BillingDashboardViewState();
}

class _BillingDashboardViewState extends State<_BillingDashboardView> {
  final _appsKey = GlobalKey();
  final _subscriptionsKey = GlobalKey();
  final _billingKey = GlobalKey();
  final _activityKey = GlobalKey();
  final _invoicesKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingCubit, BillingState>(
      builder: (context, state) {
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            final content = SingleChildScrollView(
              child: ResponsiveSection(
                padding: EdgeInsets.fromLTRB(isWide ? 8 : 24, 48, 24, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Dashboard',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Kelola aplikasi, subscription, billing wallet, aktivitas, dan invoice dari satu dashboard user.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CostikStudioTheme.slate,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isWide) ...[
                      _DashboardNavBar(
                        isCompact: true,
                        onApps: () => _scrollTo(_appsKey),
                        onSubscriptions: () => _scrollTo(_subscriptionsKey),
                        onBilling: () => _scrollTo(_billingKey),
                        onActivity: () => _scrollTo(_activityKey),
                        onInvoices: () => _scrollTo(_invoicesKey),
                      ),
                      const SizedBox(height: 22),
                    ],
                    if (snapshot.message != null) ...[
                      BillingNotice(message: snapshot.message!),
                      const SizedBox(height: 18),
                    ],
                    _DashboardSection(
                      key: _appsKey,
                      title: 'Aplikasi',
                      description: 'Pilih aplikasi aktif dan paket yang ingin dijalankan.',
                      child: PlanCatalogCard(
                        products: snapshot.products,
                        plans: snapshot.plans,
                        subscriptions: snapshot.subscriptions,
                        onSubscribe: (plan) => _checkout(context, plan),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _DashboardSection(
                      key: _subscriptionsKey,
                      title: 'Subscription',
                      description: 'Pantau paket yang masih aktif dan masa berlaku layanan.',
                      child: SubscriptionsCard(
                        products: snapshot.products,
                        plans: snapshot.plans,
                        subscriptions: snapshot.subscriptions,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _DashboardSection(
                      key: _billingKey,
                      title: 'Billing Wallet',
                      description:
                          'Top-up saldo dummy untuk pembayaran paket aplikasi.',
                      child: WalletCard(
                        balance: snapshot.wallet.balance,
                        onTopUp: context.read<BillingCubit>().topUpDummy,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _DashboardSection(
                      key: _activityKey,
                      title: 'Aktivitas Wallet',
                      description: 'Riwayat transaksi terakhir dari top-up dan pembelian paket.',
                      child: TransactionsCard(
                        transactions: snapshot.transactions,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _DashboardSection(
                      key: _invoicesKey,
                      title: 'Invoice',
                      description: 'Daftar invoice dummy yang terbentuk dari aktivitas billing.',
                      child: InvoicesCard(invoices: snapshot.invoices),
                    ),
                  ],
                ),
              ),
            );

            if (!isWide) return content;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 8, 0),
                  child: _DashboardNavBar(
                    onApps: () => _scrollTo(_appsKey),
                    onSubscriptions: () => _scrollTo(_subscriptionsKey),
                    onBilling: () => _scrollTo(_billingKey),
                    onActivity: () => _scrollTo(_activityKey),
                    onInvoices: () => _scrollTo(_invoicesKey),
                  ),
                ),
                Expanded(child: content),
              ],
            );
          },
        );
      },
    );
  }

  void _checkout(BuildContext context, BillingPlan plan) {
    context.read<BillingCubit>().checkoutPlan(plan.id);
  }
}

class _DashboardNavBar extends StatelessWidget {
  const _DashboardNavBar({
    required this.onApps,
    required this.onSubscriptions,
    required this.onBilling,
    required this.onActivity,
    required this.onInvoices,
    this.isCompact = false,
  });

  final VoidCallback onApps;
  final VoidCallback onSubscriptions;
  final VoidCallback onBilling;
  final VoidCallback onActivity;
  final VoidCallback onInvoices;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final items = [
      _DashboardNavItem('Aplikasi', Icons.apps_rounded, onApps),
      _DashboardNavItem(
        'Subscription',
        Icons.workspace_premium_rounded,
        onSubscriptions,
      ),
      _DashboardNavItem(
        'Billing',
        Icons.account_balance_wallet_rounded,
        onBilling,
      ),
      _DashboardNavItem('Aktivitas', Icons.receipt_long_rounded, onActivity),
      _DashboardNavItem('Invoice', Icons.description_rounded, onInvoices),
    ];

    final children = [
      for (final item in items)
        _DashboardNavButton(
          label: item.label,
          icon: item.icon,
          onPressed: item.onPressed,
          isCompact: isCompact,
        ),
    ];

    return Card(
      child: Container(
        width: isCompact ? double.infinity : 236,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        ),
        child: isCompact
            ? Wrap(spacing: 10, runSpacing: 10, children: children)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
                    child: Text(
                      'Dashboard Menu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: CostikStudioTheme.navy,
                      ),
                    ),
                  ),
                  ...children,
                ],
              ),
      ),
    );
  }
}

class _DashboardNavButton extends StatelessWidget {
  const _DashboardNavButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isCompact,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        foregroundColor: CostikStudioTheme.navy,
        backgroundColor: CostikStudioTheme.primary.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: isCompact ? null : const Size(double.infinity, 44),
      ),
    );
  }
}

class _DashboardNavItem {
  const _DashboardNavItem(this.label, this.icon, this.onPressed);

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _DashboardSection extends StatelessWidget {
  const _DashboardSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: CostikStudioTheme.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: CostikStudioTheme.slate, height: 1.5),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/features/billing/billing_dependencies.dart';
import 'package:costikstudio/features/billing/cubit/billing_cubit.dart';
import 'package:costikstudio/features/billing/widgets/billing_notice.dart';
import 'package:costikstudio/features/billing/widgets/invoices_card.dart';
import 'package:costikstudio/features/billing/widgets/plan_catalog_card.dart';
import 'package:costikstudio/features/billing/widgets/subscriptions_card.dart';
import 'package:costikstudio/features/billing/widgets/transactions_card.dart';
import 'package:costikstudio/features/billing/widgets/wallet_card.dart';
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

enum _DashboardTab { apps, subscriptions, billing, activity, invoices }

class _BillingDashboardView extends StatefulWidget {
  const _BillingDashboardView();

  @override
  State<_BillingDashboardView> createState() => _BillingDashboardViewState();
}

class _BillingDashboardViewState extends State<_BillingDashboardView> {
  _DashboardTab _selectedTab = _DashboardTab.apps;

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
            final isWide = constraints.maxWidth >= 900;
            final page = _DashboardPage(
              snapshot: snapshot,
              selectedTab: _selectedTab,
              onCheckout: (plan) => _checkout(context, plan),
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(
                isWide ? 24 : 16,
                28,
                isWide ? 24 : 16,
                28,
              ),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardNavBar(
                          selectedTab: _selectedTab,
                          onChanged: _selectTab,
                        ),
                        const SizedBox(width: 22),
                        Expanded(child: page),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _DashboardNavBar(
                          selectedTab: _selectedTab,
                          onChanged: _selectTab,
                          isCompact: true,
                        ),
                        const SizedBox(height: 18),
                        Expanded(child: page),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  void _selectTab(_DashboardTab tab) {
    setState(() => _selectedTab = tab);
  }

  void _checkout(BuildContext context, BillingPlan plan) {
    context.read<BillingCubit>().checkoutPlan(plan.id);
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.snapshot,
    required this.selectedTab,
    required this.onCheckout,
  });

  final BillingSnapshot snapshot;
  final _DashboardTab selectedTab;
  final ValueChanged<BillingPlan> onCheckout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _titleFor(selectedTab),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: CostikStudioTheme.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _descriptionFor(selectedTab),
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: CostikStudioTheme.slate, height: 1.45),
            ),
            const SizedBox(height: 18),
            if (snapshot.message != null) ...[
              BillingNotice(message: snapshot.message!),
              const SizedBox(height: 18),
            ],
            Expanded(child: SingleChildScrollView(child: _contentFor(context))),
          ],
        ),
      ),
    );
  }

  Widget _contentFor(BuildContext context) {
    return switch (selectedTab) {
      _DashboardTab.apps => PlanCatalogCard(
        products: snapshot.products,
        plans: snapshot.plans,
        subscriptions: snapshot.subscriptions,
        onSubscribe: onCheckout,
      ),
      _DashboardTab.subscriptions => SubscriptionsCard(
        products: snapshot.products,
        plans: snapshot.plans,
        subscriptions: snapshot.subscriptions,
      ),
      _DashboardTab.billing => WalletCard(
        balance: snapshot.wallet.balance,
        onTopUp: context.read<BillingCubit>().topUpDummy,
      ),
      _DashboardTab.activity => TransactionsCard(
        transactions: snapshot.transactions,
      ),
      _DashboardTab.invoices => InvoicesCard(invoices: snapshot.invoices),
    };
  }

  String _titleFor(_DashboardTab tab) {
    return switch (tab) {
      _DashboardTab.apps => 'Aplikasi',
      _DashboardTab.subscriptions => 'Subscription',
      _DashboardTab.billing => 'Billing Wallet',
      _DashboardTab.activity => 'Aktivitas Wallet',
      _DashboardTab.invoices => 'Invoice',
    };
  }

  String _descriptionFor(_DashboardTab tab) {
    return switch (tab) {
      _DashboardTab.apps =>
        'Pilih aplikasi aktif dan paket yang ingin dijalankan.',
      _DashboardTab.subscriptions =>
        'Pantau paket aktif dan masa berlaku layanan.',
      _DashboardTab.billing =>
        'Top-up saldo dummy untuk pembayaran paket aplikasi.',
      _DashboardTab.activity =>
        'Riwayat transaksi terakhir dari top-up dan pembelian paket.',
      _DashboardTab.invoices => 'Daftar invoice dummy dari aktivitas billing.',
    };
  }
}

class _DashboardNavBar extends StatelessWidget {
  const _DashboardNavBar({
    required this.selectedTab,
    required this.onChanged,
    this.isCompact = false,
  });

  final _DashboardTab selectedTab;
  final ValueChanged<_DashboardTab> onChanged;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _DashboardNavItem(
        _DashboardTab.apps,
        'Aplikasi',
        'Paket & produk',
        Icons.grid_view_rounded,
      ),
      _DashboardNavItem(
        _DashboardTab.subscriptions,
        'Subscription',
        'Paket aktif',
        Icons.verified_rounded,
      ),
      _DashboardNavItem(
        _DashboardTab.billing,
        'Billing',
        'Wallet & top-up',
        Icons.account_balance_wallet_rounded,
      ),
      _DashboardNavItem(
        _DashboardTab.activity,
        'Aktivitas',
        'Riwayat wallet',
        Icons.timeline_rounded,
      ),
      _DashboardNavItem(
        _DashboardTab.invoices,
        'Invoice',
        'Tagihan & bukti',
        Icons.receipt_rounded,
      ),
    ];

    return Container(
      width: isCompact ? double.infinity : 264,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CostikStudioTheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Console',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Customer portal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.58),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (isCompact)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in items)
                  _DashboardNavButton(
                    item: item,
                    selected: selectedTab == item.tab,
                    onPressed: () => onChanged(item.tab),
                    isCompact: true,
                  ),
              ],
            )
          else
            for (final item in items) ...[
              _DashboardNavButton(
                item: item,
                selected: selectedTab == item.tab,
                onPressed: () => onChanged(item.tab),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _DashboardNavButton extends StatelessWidget {
  const _DashboardNavButton({
    required this.item,
    required this.selected,
    required this.onPressed,
    this.isCompact = false,
  });

  final _DashboardNavItem item;
  final bool selected;
  final VoidCallback onPressed;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.76);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: selected
            ? const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF14B8A6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: selected ? null : Colors.transparent,
        border: Border.all(
          color: selected
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('dashboard_nav_${item.tab.name}'),
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 14,
              vertical: isCompact ? 10 : 13,
            ),
            child: Row(
              mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 18, color: foreground),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(
                              alpha: selected ? 0.78 : 0.46,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(
                      alpha: selected ? 0.8 : 0.22,
                    ),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardNavItem {
  const _DashboardNavItem(this.tab, this.label, this.subtitle, this.icon);

  final _DashboardTab tab;
  final String label;
  final String subtitle;
  final IconData icon;
}

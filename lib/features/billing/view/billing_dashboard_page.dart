import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/billing/billing_dependencies.dart';
import 'package:costikstudio/features/billing/cubit/billing_cubit.dart';
import 'package:costikstudio/features/billing/widgets/billing_history_table_card.dart';
import 'package:costikstudio/features/billing/widgets/billing_notice.dart';
import 'package:costikstudio/features/billing/widgets/invoices_card.dart';
import 'package:costikstudio/features/billing/widgets/subscriptions_card.dart';
import 'package:costikstudio/features/billing/widgets/transactions_card.dart';
import 'package:costikstudio/features/billing/widgets/wallet_card.dart';
import 'package:costikstudio/features/shared/widgets/product_card.dart';
import 'package:costikstudio/features/subscription/view/iptv_subscription_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  ProductItem? _selectedProduct;
  bool _isOrderingIptv = false;

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
              selectedProduct: _selectedProduct,
              isOrderingIptv: _isOrderingIptv,
              onSelectProduct: (product) {
                setState(() {
                  _selectedProduct = product;
                  _isOrderingIptv = false;
                });
              },
              onStartOrderIptv: () {
                setState(() {
                  _isOrderingIptv = true;
                });
              },
              onBackToProductCatalog: () {
                setState(() {
                  _selectedProduct = null;
                  _isOrderingIptv = false;
                });
              },
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
    setState(() {
      _selectedTab = tab;
      _selectedProduct = null;
      _isOrderingIptv = false;
    });
  }

  void _checkout(BuildContext context, BillingPlan plan) {
    context.read<BillingCubit>().checkoutPlan(plan.id);
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({
    required this.snapshot,
    required this.selectedTab,
    required this.selectedProduct,
    required this.isOrderingIptv,
    required this.onSelectProduct,
    required this.onStartOrderIptv,
    required this.onBackToProductCatalog,
    required this.onCheckout,
  });

  final BillingSnapshot snapshot;
  final _DashboardTab selectedTab;
  final ProductItem? selectedProduct;
  final bool isOrderingIptv;
  final ValueChanged<ProductItem> onSelectProduct;
  final VoidCallback onStartOrderIptv;
  final VoidCallback onBackToProductCatalog;
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
              BillingNotice(
                message: snapshot.message!,
                onClose: context.read<BillingCubit>().clearMessage,
              ),
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
      _DashboardTab.apps => _buildAppsTab(context),
      _DashboardTab.subscriptions => SubscriptionsCard(
        products: snapshot.products,
        plans: snapshot.plans,
        subscriptions: snapshot.subscriptions,
      ),
      _DashboardTab.billing => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WalletCard(
            balance: snapshot.wallet.balance,
            onTopUp: context.read<BillingCubit>().topUpDummy,
          ),
          const SizedBox(height: 20),
          BillingHistoryTableCard(
            transactions: snapshot.transactions,
            invoices: snapshot.invoices,
          ),
        ],
      ),
      _DashboardTab.activity => TransactionsCard(
        transactions: snapshot.transactions,
      ),
      _DashboardTab.invoices => InvoicesCard(invoices: snapshot.invoices),
    };
  }

  Widget _buildAppsTab(BuildContext context) {
    if (isOrderingIptv) {
      return IptvSubscriptionPage(
        isEmbedded: true,
        onBack: onBackToProductCatalog,
      );
    }

    if (selectedProduct != null) {
      return _EmbeddedProductDetail(
        product: selectedProduct!,
        onBack: onBackToProductCatalog,
        onSubscribe: () {
          if (selectedProduct!.id == 'costik-iptv') {
            onStartOrderIptv();
          }
        },
      );
    }

    return GridView.builder(
      itemCount: dummyProducts.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 350,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
      ),
      itemBuilder: (context, index) {
        final product = dummyProducts[index];
        return ProductCard(
          product: product,
          onTap: () => onSelectProduct(product),
        );
      },
    );
  }

  String _titleFor(_DashboardTab tab) {
    if (tab == _DashboardTab.apps) {
      if (isOrderingIptv) return 'Berlangganan Costik IPTV';
      if (selectedProduct != null) return selectedProduct!.name;
      return 'Produk';
    }
    return switch (tab) {
      _DashboardTab.apps => 'Produk',
      _DashboardTab.subscriptions => 'Subscription',
      _DashboardTab.billing => 'Billing Wallet',
      _DashboardTab.activity => 'Aktivitas Wallet',
      _DashboardTab.invoices => 'Invoice',
    };
  }

  String _descriptionFor(_DashboardTab tab) {
    if (tab == _DashboardTab.apps) {
      if (isOrderingIptv) {
        return 'Hitung kebutuhan lisensi device IPTV untuk hotel atau bisnis Anda.';
      }
      if (selectedProduct != null) {
        return selectedProduct!.tagline;
      }
      return 'Pilih produk aktif dan paket yang ingin dijalankan.';
    }
    return switch (tab) {
      _DashboardTab.apps =>
        'Pilih produk aktif dan paket yang ingin dijalankan.',
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

class _EmbeddedProductDetail extends StatelessWidget {
  const _EmbeddedProductDetail({
    required this.product,
    required this.onBack,
    required this.onSubscribe,
  });

  final ProductItem product;
  final VoidCallback onBack;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    final accent = Color(product.accentHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Kembali ke Katalog Produk'),
          style: TextButton.styleFrom(
            foregroundColor: CostikStudioTheme.slate,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      product.status.name.toUpperCase(),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: CostikStudioTheme.navy,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: CostikStudioTheme.slate,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: onSubscribe,
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('Berlangganan sekarang'),
                  ),
                  if (product.hasAdmin)
                    OutlinedButton.icon(
                      onPressed: () => context.go('/support'),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open web admin'),
                    ),
                  if (product.hasDownload)
                    OutlinedButton.icon(
                      onPressed: () => context.go(AppRoutes.apps),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download app'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Fitur Utama',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: CostikStudioTheme.navy,
          ),
        ),
        const SizedBox(height: 14),
        for (final feature in product.features)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(Icons.check_circle_rounded, color: accent),
              title: Text(
                feature,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
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
    const items = [
      _DashboardNavSection('SERVICES', [
        _DashboardNavItem(_DashboardTab.apps, 'Produk', Icons.inventory_2_rounded),
        _DashboardNavItem(
          _DashboardTab.subscriptions,
          'Subscription',
          Icons.verified_rounded,
        ),
      ]),
      _DashboardNavSection('BILLING', [
        _DashboardNavItem(
          _DashboardTab.billing,
          'Billing',
          Icons.account_balance_wallet_rounded,
        ),
        _DashboardNavItem(
          _DashboardTab.invoices,
          'Invoice',
          Icons.receipt_rounded,
        ),
      ]),
      _DashboardNavSection('ACTIVITY', [
        _DashboardNavItem(
          _DashboardTab.activity,
          'Activity',
          Icons.timeline_rounded,
        ),
      ]),
    ];

    return Container(
      width: isCompact ? double.infinity : 238,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: isCompact
          ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final section in items)
                  for (final item in section.items)
                    _DashboardNavButton(
                      item: item,
                      selected: selectedTab == item.tab,
                      onPressed: () => onChanged(item.tab),
                      isCompact: true,
                    ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                for (final section in items) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    child: Text(
                      section.title,
                      style: TextStyle(
                        color: CostikStudioTheme.slate.withValues(alpha: 0.58),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  for (final item in section.items)
                    _DashboardNavButton(
                      item: item,
                      selected: selectedTab == item.tab,
                      onPressed: () => onChanged(item.tab),
                    ),
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
    final color = selected
        ? CostikStudioTheme.primary
        : CostikStudioTheme.slate;
    return Material(
      color: selected
          ? CostikStudioTheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: ValueKey('dashboard_nav_${item.tab.name}'),
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 10,
            vertical: isCompact ? 9 : 10,
          ),
          child: Row(
            mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(item.icon, color: color, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardNavSection {
  const _DashboardNavSection(this.title, this.items);

  final String title;
  final List<_DashboardNavItem> items;
}

class _DashboardNavItem {
  const _DashboardNavItem(this.tab, this.label, this.icon);

  final _DashboardTab tab;
  final String label;
  final IconData icon;
}

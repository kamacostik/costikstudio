import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
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
import 'package:costikstudio/features/support/view/support_page.dart';
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

enum _DashboardTab { apps, subscriptions, billing, activity, invoices, support }

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
    return BlocConsumer<BillingCubit, BillingState>(
      listener: (context, state) {
        final message = state.snapshot?.message;
        final errorMessage = state.errorMessage;
        final messenger = ScaffoldMessenger.of(context);
        if (message != null && message.isNotEmpty) {
          messenger.showSnackBar(SnackBar(content: Text(message)));
        } else if (errorMessage != null && errorMessage.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text(errorMessage)),
          );
        }
      },
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
              onOpenSubscriptions: () =>
                  _selectTab(_DashboardTab.subscriptions),
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
    required this.onOpenSubscriptions,
    required this.onCheckout,
  });

  final BillingSnapshot snapshot;
  final _DashboardTab selectedTab;
  final ProductItem? selectedProduct;
  final bool isOrderingIptv;
  final ValueChanged<ProductItem> onSelectProduct;
  final VoidCallback onStartOrderIptv;
  final VoidCallback onBackToProductCatalog;
  final VoidCallback onOpenSubscriptions;
  final ValueChanged<BillingPlan> onCheckout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        child: SingleChildScrollView(
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
              if (selectedTab == _DashboardTab.apps &&
                  selectedProduct == null &&
                  !isOrderingIptv) ...[
                _DashboardSummaryStrip(snapshot: snapshot),
                const SizedBox(height: 20),
              ],
              _contentFor(context),
            ],
          ),
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
        onRenew: ({required subscriptionId, required billingCycleMonths}) =>
            context.read<BillingCubit>().renewIptvSubscription(
              subscriptionId: subscriptionId,
              billingCycleMonths: billingCycleMonths,
            ),
        onUpgradeDevice:
            ({required subscriptionId, required additionalDeviceCount}) =>
                context.read<BillingCubit>().upgradeIptvSubscriptionDevices(
                  subscriptionId: subscriptionId,
                  additionalDeviceCount: additionalDeviceCount,
                ),
        onCancel: ({required subscriptionId}) => context
            .read<BillingCubit>()
            .cancelIptvSubscription(subscriptionId: subscriptionId),
        onReactivate: ({required subscriptionId}) => context
            .read<BillingCubit>()
            .reactivateIptvSubscription(subscriptionId: subscriptionId),
      ),
      _DashboardTab.billing => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WalletCard(
            balance: snapshot.wallet.balance,
            paymentOrders: snapshot.paymentOrders,
            onTopUp: (amount) =>
                context.read<BillingCubit>().topUp(amount: amount),
          ),
          const SizedBox(height: 20),
          BillingHistoryTableCard(
            transactions: snapshot.transactions,
            invoices: snapshot.invoices,
            paymentOrders: snapshot.paymentOrders,
          ),
        ],
      ),
      _DashboardTab.activity => TransactionsCard(
        transactions: snapshot.transactions,
      ),
      _DashboardTab.invoices => InvoicesCard(invoices: snapshot.invoices),
      _DashboardTab.support => const SupportPage(isEmbedded: true),
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
        subscriptions: snapshot.subscriptions,
        onBack: onBackToProductCatalog,
        onSubscribe: () {
          if (selectedProduct!.id == 'costik-iptv') {
            onStartOrderIptv();
          }
        },
        onUpgradeDevice: onOpenSubscriptions,
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
          compact: true,
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
      _DashboardTab.support => 'Support',
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
        'Top-up saldo, pantau pembayaran pending, dan cek riwayat billing.',
      _DashboardTab.activity =>
        'Riwayat transaksi terakhir dari top-up dan pembelian paket.',
      _DashboardTab.invoices => 'Daftar invoice dari aktivitas billing.',
      _DashboardTab.support =>
        'Bantuan produk, dokumentasi, integrasi, dan saluran kontak resmi.',
    };
  }
}

class _DashboardSummaryStrip extends StatelessWidget {
  const _DashboardSummaryStrip({required this.snapshot});

  final BillingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final pendingOrders = snapshot.paymentOrders
        .where((order) => order.isPending)
        .toList(growable: false);
    final latestInvoice = snapshot.invoices.isEmpty
        ? null
        : snapshot.invoices.reduce(
            (latest, invoice) =>
                invoice.issuedAt.isAfter(latest.issuedAt) ? invoice : latest,
          );
    final activeSubscriptions = snapshot.subscriptions
        .where(
          (subscription) => subscription.status == SubscriptionStatus.active,
        )
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final cards = [
          _DashboardSummaryCard(
            icon: Icons.account_balance_wallet_rounded,
            label: 'Wallet Balance',
            value: formatRupiah(snapshot.wallet.balance),
            detail: pendingOrders.isEmpty
                ? 'Tidak ada pembayaran pending'
                : '${pendingOrders.length} pembayaran pending',
            color: CostikStudioTheme.primary,
          ),
          _DashboardSummaryCard(
            icon: Icons.verified_user_rounded,
            label: 'Active Subscription',
            value: '$activeSubscriptions aktif',
            detail: snapshot.subscriptions.isEmpty
                ? 'Belum ada paket aktif'
                : '${snapshot.subscriptions.length} total subscription',
            color: Colors.green,
          ),
          _DashboardSummaryCard(
            icon: Icons.receipt_long_rounded,
            label: 'Latest Invoice',
            value: latestInvoice == null
                ? 'Belum ada'
                : formatRupiah(latestInvoice.amount),
            detail:
                latestInvoice?.number ??
                'Invoice akan muncul setelah transaksi',
            color: Colors.indigo,
          ),
          _DashboardSummaryCard(
            icon: Icons.pending_actions_rounded,
            label: 'Payment Status',
            value: pendingOrders.isEmpty
                ? 'Clear'
                : '${pendingOrders.length} pending',
            detail: pendingOrders.isEmpty
                ? 'Semua transaksi sudah selesai'
                : 'Periksa atau batalkan di tab Billing',
            color: pendingOrders.isEmpty ? Colors.teal : Colors.orange,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (card) => SizedBox(
                  width: constraints.maxWidth >= 520
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth,
                  child: card,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _DashboardSummaryCard extends StatelessWidget {
  const _DashboardSummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CostikStudioTheme.slate,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: CostikStudioTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: CostikStudioTheme.slate,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmbeddedProductDetail extends StatelessWidget {
  const _EmbeddedProductDetail({
    required this.product,
    required this.subscriptions,
    required this.onBack,
    required this.onSubscribe,
    required this.onUpgradeDevice,
  });

  final ProductItem product;
  final List<Subscription> subscriptions;
  final VoidCallback onBack;
  final VoidCallback onSubscribe;
  final VoidCallback onUpgradeDevice;

  @override
  Widget build(BuildContext context) {
    final accent = Color(product.accentHex);

    // Find any existing IPTV subscription (active or cancelled)
    final existingIptvSubscription = product.id == 'costik-iptv'
        ? subscriptions
              .where((s) => s.productId == 'costik-iptv')
              .where(
                (s) =>
                    s.status == SubscriptionStatus.active ||
                    s.status == SubscriptionStatus.cancelled,
              )
              .firstOrNull
        : null;
    final hasExistingIptvSubscription = existingIptvSubscription != null;
    final isIptvActive =
        existingIptvSubscription?.status == SubscriptionStatus.active;
    final isIptvCancelled =
        existingIptvSubscription?.status == SubscriptionStatus.cancelled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Kembali ke Katalog Produk'),
          style: TextButton.styleFrom(foregroundColor: CostikStudioTheme.slate),
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
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: CostikStudioTheme.slate, height: 1.6),
              ),
              const SizedBox(height: 24),
              if (hasExistingIptvSubscription) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isIptvCancelled
                        ? Colors.orange.withValues(alpha: 0.08)
                        : CostikStudioTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isIptvCancelled
                          ? Colors.orange.withValues(alpha: 0.16)
                          : CostikStudioTheme.primary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: isIptvCancelled
                            ? Colors.orange
                            : CostikStudioTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isIptvCancelled
                              ? 'Subscription IPTV Anda sedang tidak aktif (cancelled). Aktifkan kembali subscription Anda di halaman Subscription untuk melanjutkan layanan.'
                              : 'Subscription IPTV Sudah Aktif. Untuk menambah kamar/device, gunakan fitur Upgrade Device pada halaman Subscription.',
                          style: const TextStyle(
                            color: CostikStudioTheme.navy,
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (isIptvActive)
                    FilledButton.icon(
                      onPressed: onUpgradeDevice,
                      icon: const Icon(Icons.add_to_queue_rounded),
                      label: const Text('Upgrade Device'),
                    )
                  else if (isIptvCancelled)
                    FilledButton.icon(
                      onPressed: onUpgradeDevice,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Kelola Subscription'),
                    )
                  else
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
        _DashboardNavItem(
          _DashboardTab.apps,
          'Produk',
          Icons.inventory_2_rounded,
        ),
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
      _DashboardNavSection('HELP & SUPPORT', [
        _DashboardNavItem(
          _DashboardTab.support,
          'Support',
          Icons.help_outline_rounded,
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

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/billing/admin/admin_billing_cubit.dart';
import 'package:costikstudio/features/billing/admin/dummy_admin_billing_repository.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

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
        final activeSubs =
            snapshot.subscriptionMetrics
                .where((m) => m.label == 'Active Subscriptions')
                .map((m) => m.value)
                .firstOrNull ??
            '-';
        final totalDevices =
            snapshot.subscriptionMetrics
                .where((m) => m.label == 'Total Devices Monitored')
                .map((m) => m.value)
                .firstOrNull ??
            '-';
        final totalCustomers = snapshot.customerWallets.length;

        return SingleChildScrollView(
          child: ResponsiveSection(
            maxWidth: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionEyebrow(label: 'CostikStudio Ops'),
                const SizedBox(height: 8),
                Text(
                  'Ringkasan Admin',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau billing, subscription, dan tenant Signage dari satu dashboard.',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: CostikStudioTheme.slate, height: 1.5),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 1080;

                    final revenueTodayStr = formatRupiah(
                      snapshot.revenueToday.toInt(),
                    );
                    final revenueMonthStr = formatRupiah(
                      snapshot.revenueMonth.toInt(),
                    );

                    final kpis = _KpiGrid(
                      cards: [
                        _KpiData(
                          icon: Icons.payments_outlined,
                          label: 'Hari Ini',
                          value: revenueTodayStr,
                          trend: 'Pemasukan hari ini',
                        ),
                        _KpiData(
                          icon: Icons.account_balance_rounded,
                          label: 'Bulan Ini',
                          value: revenueMonthStr,
                          trend: 'Pemasukan bulan ini',
                        ),
                        _KpiData(
                          icon: Icons.people_outline_rounded,
                          label: 'Total Users',
                          value: '$totalCustomers',
                          trend: '+12% minggu ini',
                        ),
                        _KpiData(
                          icon: Icons.verified_user_outlined,
                          label: 'Sub Aktif',
                          value: activeSubs,
                          trend: '+5% minggu ini',
                        ),
                        _KpiData(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Top Up Pending',
                          value: '$pendingTopUps',
                          trend: 'Butuh approval',
                          isAlert: pendingTopUps > 0,
                        ),
                        _KpiData(
                          icon: Icons.monitor_outlined,
                          label: 'Device Aktif',
                          value: totalDevices,
                          trend: 'Total layar dipantau',
                        ),
                      ],
                    );

                    final middleRow = isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: const _TransactionChartCard(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 1,
                                child: _HeroPanel(
                                  pendingTopUps: pendingTopUps,
                                  activeSubs: activeSubs,
                                  onOpenBilling: () =>
                                      context.go(AppRoutes.adminBilling),
                                  onOpenSignage: () =>
                                      context.go(AppRoutes.adminSignage),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              kpis,
                              const SizedBox(height: 16),
                              const _TransactionChartCard(),
                              const SizedBox(height: 16),
                              _HeroPanel(
                                pendingTopUps: pendingTopUps,
                                activeSubs: activeSubs,
                                onOpenBilling: () =>
                                    context.go(AppRoutes.adminBilling),
                                onOpenSignage: () =>
                                    context.go(AppRoutes.adminSignage),
                              ),
                            ],
                          );

                    if (!isWide) return middleRow;

                    return Column(
                      children: [kpis, const SizedBox(height: 16), middleRow],
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  'Modul Admin',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Empat area kerja utama, satu pola navigasi yang konsisten.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: CostikStudioTheme.slate, height: 1.5),
                ),
                const SizedBox(height: 16),
                _ModuleGrid(
                  modules: [
                    _ModuleData(
                      icon: Icons.receipt_long_rounded,
                      title: 'Billing & Subscription',
                      description: 'Setujui top up manual, pantau wallet customer, dan kelola subscription IPTV.',
                      ctaLabel: 'Buka Billing',
                      onTap: () => context.go(AppRoutes.adminBilling),
                    ),
                    _ModuleData(
                      icon: Icons.tv_rounded,
                      title: 'Signage Tenants',
                      description: 'Daftar tenant/hotel Signage customer beserta status device dan subscription.',
                      ctaLabel: 'Buka Signage',
                      onTap: () => context.go(AppRoutes.adminSignage),
                    ),
                    _ModuleData(
                      icon: Icons.photo_library_rounded,
                      title: 'Product Gallery',
                      description: 'Upload screenshot aplikasi, pilih cover image, dan kelola gallery produk member.',
                      ctaLabel: 'Kelola Gallery',
                      onTap: () => context.go(AppRoutes.adminProductGallery),
                    ),
                    _ModuleData(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Akun Admin',
                      description: 'Profil dan sesi akun administrator.',
                      ctaLabel: 'Buka Akun',
                      onTap: () => context.go(AppRoutes.account),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionEyebrow extends StatelessWidget {
  const _SectionEyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: CostikStudioTheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.pendingTopUps,
    required this.activeSubs,
    required this.onOpenBilling,
    required this.onOpenSignage,
  });

  final int pendingTopUps;
  final String activeSubs;
  final VoidCallback onOpenBilling;
  final VoidCallback onOpenSignage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 760;
        final body = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _heroCopy(context)),
                  const SizedBox(width: 24),
                  _heroStat(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroCopy(context),
                  const SizedBox(height: 20),
                  _heroStat(),
                ],
              );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: CostikStudioTheme.navy,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -70,
                top: -80,
                child: _glowCircle(220, Colors.white.withValues(alpha: 0.07)),
              ),
              Positioned(
                right: 60,
                bottom: -110,
                child: _glowCircle(
                  180,
                  CostikStudioTheme.primary.withValues(alpha: 0.35),
                ),
              ),
              body,
            ],
          ),
        );
      },
    );
  }

  Widget _heroCopy(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 6),
              Text(
                pendingTopUps == 0
                    ? 'Semua top up sudah diproses'
                    : '$pendingTopUps top up menunggu persetujuan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Operasional hari ini, dalam satu pandangan.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$activeSubs subscription aktif. Mulai dari approval billing, lalu cek tenant Signage bila perlu.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: onOpenBilling,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: CostikStudioTheme.navy,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Lihat Antrian'),
            ),
            OutlinedButton(
              onPressed: onOpenSignage,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Buka Signage'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _heroStat() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 14),
          Text(
            '$pendingTopUps',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Antrian Top Up',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            'Butuh persetujuan admin',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.icon,
    required this.label,
    required this.value,
    this.trend = '',
    this.isAlert = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool isAlert;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.cards});

  final List<_KpiData> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: constraints.maxWidth > 1200
                ? 6
                : constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 500
                ? 2
                : 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 104,
          ),
          itemBuilder: (context, index) => _KpiCard(data: cards[index]),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    final color = data.isAlert ? Colors.redAccent : CostikStudioTheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: color, size: 22),
                ),
                if (data.isAlert)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Action Needed',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              data.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: data.isAlert ? Colors.redAccent : CostikStudioTheme.navy,
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              data.trend,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: data.isAlert
                    ? Colors.redAccent.withValues(alpha: 0.8)
                    : const Color(0xFF16A34A),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleData {
  const _ModuleData({
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
}

class _ModuleGrid extends StatelessWidget {
  const _ModuleGrid({required this.modules});

  final List<_ModuleData> modules;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1080
            ? 4
            : constraints.maxWidth > 820
            ? 2
            : 1;
        return GridView.builder(
          itemCount: modules.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: crossAxisCount == 4 ? 196 : 168,
          ),
          itemBuilder: (context, index) =>
              _ModuleTile(module: modules[index], compact: crossAxisCount == 4),
        );
      },
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({required this.module, this.compact = false});

  final _ModuleData module;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: module.onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: CostikStudioTheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    module.icon,
                    color: CostikStudioTheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  module.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CostikStudioTheme.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    letterSpacing: -0.2,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  module.ctaLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CostikStudioTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: module.onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: CostikStudioTheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  module.icon,
                  color: CostikStudioTheme.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      module.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CostikStudioTheme.navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      module.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CostikStudioTheme.slate,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      module.ctaLabel,
                      style: const TextStyle(
                        color: CostikStudioTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.10),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: CostikStudioTheme.navy,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionChartCard extends StatelessWidget {
  const _TransactionChartCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.show_chart_rounded,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Grafik Transaksi & Top Up',
                      style: TextStyle(
                        color: CostikStudioTheme.navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '7 Hari Terakhir',
                      style: TextStyle(
                        color: CostikStudioTheme.slate,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 20,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                            color: CostikStudioTheme.slate,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          );
                          String text;
                          switch (value.toInt()) {
                            case 0:
                              text = 'Sen';
                              break;
                            case 1:
                              text = 'Sel';
                              break;
                            case 2:
                              text = 'Rab';
                              break;
                            case 3:
                              text = 'Kam';
                              break;
                            case 4:
                              text = 'Jum';
                              break;
                            case 5:
                              text = 'Sab';
                              break;
                            case 6:
                              text = 'Min';
                              break;
                            default:
                              text = '';
                          }
                          return SideTitleWidget(
                            meta: meta,
                            space: 10,
                            child: Text(text, style: style),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.black.withValues(alpha: 0.05),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    _makeGroup(0, 5, 3),
                    _makeGroup(1, 8, 5),
                    _makeGroup(2, 6, 2),
                    _makeGroup(3, 12, 6),
                    _makeGroup(4, 15, 8),
                    _makeGroup(5, 18, 10),
                    _makeGroup(6, 10, 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: CostikStudioTheme.primary,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
        BarChartRodData(
          toY: y2,
          color: Colors.blue.shade200,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

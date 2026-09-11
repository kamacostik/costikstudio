import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:flutter/material.dart';

class SubscriptionsCard extends StatelessWidget {
  const SubscriptionsCard({
    super.key,
    required this.products,
    required this.plans,
    required this.subscriptions,
    required this.onRenew,
    required this.onUpgradeDevice,
    required this.onCancel,
  });

  final List<BillingProduct> products;
  final List<BillingPlan> plans;
  final List<Subscription> subscriptions;
  final Future<void> Function({
    required String subscriptionId,
    required int billingCycleMonths,
  })
  onRenew;
  final Future<void> Function({
    required String subscriptionId,
    required int additionalDeviceCount,
  })
  onUpgradeDevice;
  final Future<void> Function({required String subscriptionId}) onCancel;

  BillingProduct? _productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  BillingPlan? _planById(String id) {
    for (final plan in plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: CostikStudioTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: CostikStudioTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Active subscriptions',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const Text(
                        'Paket aktif, jumlah device, masa berlaku, dan status layanan.',
                        style: TextStyle(color: CostikStudioTheme.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (subscriptions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada paket berlangganan aktif.'),
              )
            else
              for (final subscription in subscriptions)
                _SubscriptionRow(
                  subscription: subscription,
                  product: _productById(subscription.productId),
                  plan: _planById(subscription.planId),
                  onRenew: onRenew,
                  onUpgradeDevice: onUpgradeDevice,
                  onCancel: onCancel,
                ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  const _SubscriptionRow({
    required this.subscription,
    required this.product,
    required this.plan,
    required this.onRenew,
    required this.onUpgradeDevice,
    required this.onCancel,
  });

  final Subscription subscription;
  final BillingProduct? product;
  final BillingPlan? plan;
  final Future<void> Function({
    required String subscriptionId,
    required int billingCycleMonths,
  })
  onRenew;
  final Future<void> Function({
    required String subscriptionId,
    required int additionalDeviceCount,
  })
  onUpgradeDevice;
  final Future<void> Function({required String subscriptionId}) onCancel;

  String get _productName => product?.name ?? subscription.productId;
  int get _remainingDays =>
      subscription.expiresAt.difference(DateTime.now()).inDays;
  int get _monthlyRenewalAmount => subscription.deviceCount * 15000;

  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Batalkan Langganan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_productName),
            const SizedBox(height: 8),
            const Text(
              'Apakah Anda yakin ingin membatalkan langganan IPTV ini? Status akan menjadi dibatalkan.',
              style: TextStyle(color: CostikStudioTheme.slate),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await onCancel(subscriptionId: subscription.id);
  }

  Future<void> _showUpgradeDeviceDialog(BuildContext context) async {
    final additionalDevices = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Upgrade Device IPTV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_productName),
            const SizedBox(height: 8),
            Text(
              'Device aktif sekarang: ${subscription.deviceCount}',
              style: const TextStyle(color: CostikStudioTheme.slate),
            ),
            const SizedBox(height: 8),
            Text(
              'Biaya: ${formatRupiah(15000)} / device / bulan x ${subscription.billingCycleMonths} bulan',
              style: const TextStyle(color: CostikStudioTheme.slate),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in const [1, 2, 5, 10])
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(dialogCtx).pop(option),
                    child: Text(
                      '+$option Device • ${formatRupiah(option * 15000 * subscription.billingCycleMonths)}',
                    ),
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

    if (additionalDevices == null || !context.mounted) return;
    await onUpgradeDevice(
      subscriptionId: subscription.id,
      additionalDeviceCount: additionalDevices,
    );
  }

  Future<void> _showRenewDialog(BuildContext context) async {
    final months = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Perpanjang Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_productName),
            const SizedBox(height: 8),
            Text(
              '${subscription.deviceCount} device x ${formatRupiah(15000)} / bulan',
              style: const TextStyle(color: CostikStudioTheme.slate),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final option in const [1, 3, 6, 12])
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(dialogCtx).pop(option),
                    child: Text(
                      '$option Bulan • ${formatRupiah(_monthlyRenewalAmount * option)}',
                    ),
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

    if (months == null || !context.mounted) return;
    await onRenew(subscriptionId: subscription.id, billingCycleMonths: months);
  }

  void _showSubscriptionDetails(BuildContext context) {
    final remainingText = _remainingDays < 0
        ? 'Expired'
        : _remainingDays == 0
        ? 'Berakhir hari ini'
        : '$_remainingDays hari lagi';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: CostikStudioTheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.tv_rounded,
                        color: CostikStudioTheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _productName,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Subscription aktif untuk ${subscription.deviceCount} device selama ${subscription.billingCycleMonths} bulan.',
                            style: const TextStyle(
                              color: CostikStudioTheme.slate,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(status: subscription.status),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.devices_rounded,
                        label: 'Jumlah Device',
                        value: '${subscription.deviceCount}',
                        helper: 'Device aktif',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.calendar_month_rounded,
                        label: 'Siklus',
                        value: '${subscription.billingCycleMonths} Bulan',
                        helper: 'Periode tagihan',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.timelapse_rounded,
                        label: 'Sisa Masa',
                        value: remainingText,
                        helper: 'Sampai expired',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Paket',
                        style: TextStyle(
                          color: CostikStudioTheme.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: 'Subscription ID',
                        value: subscription.id,
                      ),
                      _DetailRow(
                        label: 'Product ID',
                        value: subscription.productId,
                      ),
                      _DetailRow(
                        label: 'Plan',
                        value: plan?.name ?? 'IPTV Wallet Checkout',
                      ),
                      _DetailRow(
                        label: 'Tanggal Mulai',
                        value: _formatFullDate(subscription.startedAt),
                      ),
                      _DetailRow(
                        label: 'Berlaku Hingga',
                        value: _formatFullDate(subscription.expiresAt),
                      ),
                      _DetailRow(
                        label: 'Renewal 1 Bulan',
                        value: formatRupiah(_monthlyRenewalAmount),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        _showCancelDialog(context);
                      },
                      child: const Text('Batalkan Langganan'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Tutup'),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        _showUpgradeDeviceDialog(context);
                      },
                      icon: const Icon(Icons.add_to_queue_rounded, size: 16),
                      label: const Text('Upgrade Device'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        _showRenewDialog(context);
                      },
                      icon: const Icon(Icons.update_rounded, size: 16),
                      label: const Text('Renew / Extend'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 650;
            final actions = [
              OutlinedButton.icon(
                onPressed: () => _showSubscriptionDetails(context),
                icon: const Icon(Icons.info_outline_rounded, size: 16),
                label: const Text('View Details'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showUpgradeDeviceDialog(context),
                icon: const Icon(Icons.add_to_queue_rounded, size: 16),
                label: const Text('Upgrade Device'),
              ),
              FilledButton.icon(
                onPressed: () => _showRenewDialog(context),
                icon: const Icon(Icons.update_rounded, size: 16),
                label: const Text('Renew'),
              ),
            ];

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: CostikStudioTheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: CostikStudioTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    _productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _StatusPill(
                                  status: subscription.status,
                                  compact: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _MiniMeta(
                                  icon: Icons.devices_rounded,
                                  text: '${subscription.deviceCount} Device',
                                ),
                                _MiniMeta(
                                  icon: Icons.calendar_month_rounded,
                                  text:
                                      '${subscription.billingCycleMonths} Bulan',
                                ),
                                _MiniMeta(
                                  icon: Icons.event_available_rounded,
                                  text:
                                      'Expired ${_shortDate(subscription.expiresAt)}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              );
            }

            return Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: CostikStudioTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: CostikStudioTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusPill(
                            status: subscription.status,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MiniMeta(
                            icon: Icons.devices_rounded,
                            text: '${subscription.deviceCount} Device',
                          ),
                          _MiniMeta(
                            icon: Icons.calendar_month_rounded,
                            text: '${subscription.billingCycleMonths} Bulan',
                          ),
                          _MiniMeta(
                            icon: Icons.event_available_rounded,
                            text:
                                'Expired ${_shortDate(subscription.expiresAt)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CostikStudioTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CostikStudioTheme.primary.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: CostikStudioTheme.primary),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: CostikStudioTheme.slate,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: CostikStudioTheme.navy,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            style: const TextStyle(
              color: CostikStudioTheme.slate,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: CostikStudioTheme.slate),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, this.compact = false});

  final SubscriptionStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isActive = status == SubscriptionStatus.active;
    final color = isActive ? Colors.green : CostikStudioTheme.amber;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: compact ? 10 : 12,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: CostikStudioTheme.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _shortDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _formatFullDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

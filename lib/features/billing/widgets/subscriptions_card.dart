import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:flutter/material.dart';

class SubscriptionsCard extends StatelessWidget {
  const SubscriptionsCard({
    super.key,
    required this.products,
    required this.plans,
    required this.subscriptions,
  });

  final List<BillingProduct> products;
  final List<BillingPlan> plans;
  final List<Subscription> subscriptions;

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
            Text(
              'Active subscriptions',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
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
  });

  final Subscription subscription;
  final BillingProduct? product;
  final BillingPlan? plan;

  void _showSubscriptionDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.stars_rounded, color: CostikStudioTheme.primary),
            const SizedBox(width: 8),
            Text(product?.name ?? subscription.productId),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Subscription ID', value: subscription.id),
            _DetailRow(
              label: 'Jumlah Device',
              value: '${subscription.deviceCount} Device',
            ),
            _DetailRow(
              label: 'Siklus Tagihan',
              value: '${subscription.billingCycleMonths} Bulan',
            ),
            _DetailRow(
              label: 'Status',
              value: subscription.status.name.toUpperCase(),
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
              label: 'Perpanjangan',
              value: subscription.autoRenew ? 'Otomatis' : 'Manual',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: CostikStudioTheme.background),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              color: CostikStudioTheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? subscription.productId,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${subscription.deviceCount} Device • ${subscription.billingCycleMonths} Bulan • Expired ${_shortDate(subscription.expiresAt)}',
                    style: const TextStyle(
                      color: CostikStudioTheme.slate,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showSubscriptionDetails(context),
              icon: const Icon(Icons.info_outline_rounded, size: 16),
              label: const Text('View Details'),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                fontWeight: FontWeight.w600,
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

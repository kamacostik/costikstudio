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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: CostikStudioTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? subscription.productId,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${plan?.name ?? subscription.planId} • expires ${_shortDate(subscription.expiresAt)}',
                  style: const TextStyle(color: CostikStudioTheme.slate),
                ),
              ],
            ),
          ),
          Chip(label: Text(subscription.autoRenew ? 'Auto renew' : 'Manual')),
        ],
      ),
    );
  }
}

String _shortDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

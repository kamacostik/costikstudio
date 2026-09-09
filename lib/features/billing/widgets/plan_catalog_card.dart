import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:flutter/material.dart';

class PlanCatalogCard extends StatelessWidget {
  const PlanCatalogCard({
    super.key,
    required this.products,
    required this.plans,
    required this.subscriptions,
    required this.onSubscribe,
  });

  final List<BillingPlan> plans;
  final List<BillingProduct> products;
  final List<Subscription> subscriptions;
  final ValueChanged<BillingPlan> onSubscribe;

  BillingProduct? _productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
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
              'Available plans',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (final plan in plans)
              _PlanRow(
                plan: plan,
                product: _productById(plan.productId),
                isActive: subscriptions.any(
                  (subscription) => subscription.productId == plan.productId,
                ),
                onSubscribe: onSubscribe,
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.product,
    required this.isActive,
    required this.onSubscribe,
  });

  final BillingPlan plan;
  final BillingProduct? product;
  final bool isActive;
  final ValueChanged<BillingPlan> onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CostikStudioTheme.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? plan.productId,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${plan.name} • ${plan.durationDays} days • ${plan.features.join(', ')}',
                  style: const TextStyle(color: CostikStudioTheme.slate),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRupiah(plan.price),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => onSubscribe(plan),
                child: Text('${isActive ? 'Renew' : 'Subscribe'} ${plan.name}'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

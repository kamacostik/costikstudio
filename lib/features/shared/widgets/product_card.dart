import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, this.compact = false});

  final ProductItem product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = Color(product.accentHex);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.go('/products/${product.id}'),
        child: Padding(
          padding: EdgeInsets.all(compact ? 18 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconForCategory(product.category),
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  _StatusChip(status: product.status),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: CostikStudioTheme.navy,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.tagline,
                maxLines: compact ? 3 : 4,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: CostikStudioTheme.slate, height: 1.5),
              ),
              if (!compact) ...[
                const SizedBox(height: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final feature in product.features.take(2))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: accent,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'View details',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, color: accent, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(ProductCategory category) {
    return switch (category) {
      ProductCategory.business => Icons.point_of_sale_rounded,
      ProductCategory.hospitality => Icons.tv_rounded,
      ProductCategory.productivity => Icons.groups_rounded,
      ProductCategory.freeApp => Icons.download_for_offline_rounded,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ProductStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ProductStatus.live => ('Live', const Color(0xFF16A34A)),
      ProductStatus.beta => ('Beta', const Color(0xFF2563EB)),
      ProductStatus.comingSoon => ('Soon', const Color(0xFFF59E0B)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

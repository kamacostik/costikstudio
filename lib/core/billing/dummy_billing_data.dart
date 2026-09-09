import 'package:costikstudio/core/billing/billing_core.dart';

const dummyBillingProducts = <BillingProduct>[
  BillingProduct(
    id: 'costik-signage',
    name: 'Costik Signage',
    category: BillingProductCategory.signage,
  ),
  BillingProduct(
    id: 'costik-iptv',
    name: 'Costik IPTV',
    category: BillingProductCategory.iptv,
  ),
  BillingProduct(
    id: 'costik-hris',
    name: 'Costik HRIS',
    category: BillingProductCategory.hris,
  ),
];

const dummyBillingPlans = <BillingPlan>[
  BillingPlan(
    id: 'signage-basic',
    productId: 'costik-signage',
    name: 'Basic',
    price: 50000,
    durationDays: 30,
    features: ['3 screens', '1 location'],
  ),
  BillingPlan(
    id: 'signage-pro',
    productId: 'costik-signage',
    name: 'Pro',
    price: 150000,
    durationDays: 30,
    features: ['10 screens', '3 locations', 'Playlist schedule'],
  ),
  BillingPlan(
    id: 'iptv-hotel-pro',
    productId: 'costik-iptv',
    name: 'Hotel Pro',
    price: 300000,
    durationDays: 30,
    features: ['50 rooms', 'Live TV', 'Guest information'],
  ),
  BillingPlan(
    id: 'hris-starter',
    productId: 'costik-hris',
    name: 'Starter',
    price: 75000,
    durationDays: 30,
    features: ['10 employees', 'Attendance', 'Shift schedule'],
  ),
];

final dummySubscriptions = <Subscription>[
  Subscription(
    id: 'sub-demo-signage',
    userId: 'demo-user',
    productId: 'costik-signage',
    planId: 'signage-pro',
    status: SubscriptionStatus.active,
    startedAt: DateTime(2026, 9, 1),
    expiresAt: DateTime(2026, 10, 1),
    autoRenew: true,
  ),
  Subscription(
    id: 'sub-demo-iptv',
    userId: 'demo-user',
    productId: 'costik-iptv',
    planId: 'iptv-hotel-pro',
    status: SubscriptionStatus.active,
    startedAt: DateTime(2026, 9, 5),
    expiresAt: DateTime(2026, 10, 5),
    autoRenew: false,
  ),
];

BillingProduct? dummyBillingProductById(String id) {
  for (final product in dummyBillingProducts) {
    if (product.id == id) return product;
  }
  return null;
}

BillingPlan? dummyBillingPlanById(String id) {
  for (final plan in dummyBillingPlans) {
    if (plan.id == id) return plan;
  }
  return null;
}

List<BillingPlan> dummyPlansForProduct(String productId) {
  return dummyBillingPlans
      .where((plan) => plan.productId == productId)
      .toList();
}

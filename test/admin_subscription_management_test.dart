import 'package:costikstudio/features/billing/admin/admin_billing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AdminSubscriptionRecord model serializes and formats correctly', () {
    final sub = AdminSubscriptionRecord(
      id: 'sub-001',
      userId: 'user-001',
      customerEmail: 'hotel@kendari.com',
      productName: 'Costik IPTV',
      deviceCount: 10,
      billingCycleMonths: 3,
      statusText: 'active',
      startedAt: DateTime(2026, 9, 1),
      expiresAt: DateTime(2026, 12, 1),
    );

    expect(sub.id, 'sub-001');
    expect(sub.customerEmail, 'hotel@kendari.com');
    expect(sub.deviceCount, 10);
    expect(sub.billingCycleMonths, 3);
    expect(sub.statusText, 'active');
  });
}

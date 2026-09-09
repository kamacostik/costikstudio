import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:costikstudio/features/billing/billing_dependencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('provides dummy billing repository through dependency factory', () {
    final repository = createBillingRepository();

    expect(repository, isA<BillingRepository>());
    expect(repository, isA<DummyBillingRepository>());
  });
}

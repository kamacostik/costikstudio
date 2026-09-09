import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/billing/dummy_billing_repository.dart';

BillingRepository createBillingRepository() {
  return DummyBillingRepository();
}

import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:costikstudio/core/billing/supabase_billing_repository.dart';
import 'package:costikstudio/core/supabase/supabase_config.dart';

BillingRepository createBillingRepository() {
  if (SupabaseConfig.isConfigured) {
    return const SupabaseBillingRepository();
  }

  return DummyBillingRepository();
}

import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/billing/dummy_billing_repository.dart';
import 'package:costikstudio/core/billing/supabase_billing_repository.dart';
import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:costikstudio/features/billing/billing_dependencies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => SupabaseConfig.load(const {}));

  test('provides dummy billing repository when Supabase env is missing', () {
    SupabaseConfig.load(const {});

    final repository = createBillingRepository();

    expect(repository, isA<BillingRepository>());
    expect(repository, isA<DummyBillingRepository>());
  });

  test(
    'provides Supabase billing repository when Supabase env is configured',
    () {
      SupabaseConfig.load(const {
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_ANON_KEY': 'public-anon-key',
      });

      final repository = createBillingRepository();

      expect(repository, isA<BillingRepository>());
      expect(repository, isA<SupabaseBillingRepository>());
    },
  );
}

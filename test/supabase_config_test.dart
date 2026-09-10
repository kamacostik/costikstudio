import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => SupabaseConfig.load(const {}));

  test('Supabase config remains optional when env values are missing', () {
    SupabaseConfig.load(const {});

    expect(SupabaseConfig.url, isEmpty);
    expect(SupabaseConfig.anonKey, isEmpty);
    expect(SupabaseConfig.sumopodCreatePaymentWebhookUrl, isEmpty);
    expect(SupabaseConfig.isConfigured, isFalse);
  });

  test('Supabase config loads url and anon key from env map', () {
    SupabaseConfig.load(const {
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_ANON_KEY': 'public-anon-key',
      'SUMOPOD_CREATE_PAYMENT_WEBHOOK_URL':
          'https://n8n.example.com/webhook/create-payment',
    });

    expect(SupabaseConfig.url, 'https://example.supabase.co');
    expect(SupabaseConfig.anonKey, 'public-anon-key');
    expect(
      SupabaseConfig.sumopodCreatePaymentWebhookUrl,
      'https://n8n.example.com/webhook/create-payment',
    );
    expect(SupabaseConfig.isConfigured, isTrue);
  });
}

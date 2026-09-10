import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Supabase config remains optional when dart defines are missing', () {
    expect(SupabaseConfig.url, isEmpty);
    expect(SupabaseConfig.anonKey, isEmpty);
    expect(SupabaseConfig.isConfigured, isFalse);
  });
}

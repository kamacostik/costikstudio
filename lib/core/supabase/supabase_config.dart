class SupabaseConfig {
  const SupabaseConfig._();

  static const _definedSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const _definedSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const _definedSumopodCreatePaymentWebhookUrl = String.fromEnvironment(
    'SUMOPOD_CREATE_PAYMENT_WEBHOOK_URL',
  );

  static String url = '';
  static String anonKey = '';
  static String sumopodCreatePaymentWebhookUrl = '';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static void load(Map<String, String> env) {
    url = _preferDartDefine(_definedSupabaseUrl, env['SUPABASE_URL']);
    anonKey = _preferDartDefine(
      _definedSupabaseAnonKey,
      env['SUPABASE_ANON_KEY'],
    );
    sumopodCreatePaymentWebhookUrl = _preferDartDefine(
      _definedSumopodCreatePaymentWebhookUrl,
      env['SUMOPOD_CREATE_PAYMENT_WEBHOOK_URL'],
    );
  }

  static String _preferDartDefine(String dartDefineValue, String? envValue) {
    final fromDefine = dartDefineValue.trim();
    if (fromDefine.isNotEmpty) return fromDefine;
    return envValue?.trim() ?? '';
  }
}

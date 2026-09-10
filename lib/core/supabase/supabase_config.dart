class SupabaseConfig {
  const SupabaseConfig._();

  static String url = '';
  static String anonKey = '';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  static void load(Map<String, String> env) {
    url = env['SUPABASE_URL']?.trim() ?? '';
    anonKey = env['SUPABASE_ANON_KEY']?.trim() ?? '';
  }
}

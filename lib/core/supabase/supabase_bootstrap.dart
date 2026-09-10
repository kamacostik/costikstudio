import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapSupabase() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'assets/env/.env');
  } on Object {
    // Keep local tests and fresh clones runnable before real env values exist.
  }

  SupabaseConfig.load(dotenv.env);

  if (!SupabaseConfig.isConfigured) return;

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
}

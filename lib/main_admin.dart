import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:costikstudio/core/supabase/supabase_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  usePathUrlStrategy();
  await bootstrapSupabase();
  runApp(const CostikStudioApp(experience: AppExperience.admin));
}

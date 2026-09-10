import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:costikstudio/core/supabase/supabase_bootstrap.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  await bootstrapSupabase();
  runApp(const CostikStudioApp(experience: AppExperience.admin));
}

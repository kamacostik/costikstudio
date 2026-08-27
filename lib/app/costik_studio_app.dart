import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/router/app_router.dart';
import 'package:flutter/material.dart';

class CostikStudioApp extends StatelessWidget {
  const CostikStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CostikStudio',
      debugShowCheckedModeBanner: false,
      theme: CostikStudioTheme.light,
      routerConfig: appRouter,
    );
  }
}

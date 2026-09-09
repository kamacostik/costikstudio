import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/router/app_router.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CostikStudioApp extends StatelessWidget {
  const CostikStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(),
      child: MaterialApp.router(
        title: 'CostikStudio',
        debugShowCheckedModeBanner: false,
        theme: CostikStudioTheme.light,
        routerConfig: appRouter,
      ),
    );
  }
}

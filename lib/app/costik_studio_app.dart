import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/router/app_router.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/products/cubit/product_catalog_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CostikStudioApp extends StatelessWidget {
  const CostikStudioApp({super.key, this.experience = AppExperience.user});

  final AppExperience experience;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()..restoreSession()),
        BlocProvider(create: (_) => ProductCatalogCubit()..load()),
      ],
      child: AppExperienceScope(
        experience: experience,
        child: BlocBuilder<AuthCubit, AuthState>(
          buildWhen: (previous, current) =>
              previous.isSessionRestored != current.isSessionRestored,
          builder: (context, authState) {
            final title = experience == AppExperience.admin
                ? 'CostikStudio Admin'
                : 'CostikStudio';
            if (!authState.isSessionRestored) {
              return MaterialApp(
                title: title,
                debugShowCheckedModeBanner: false,
                theme: CostikStudioTheme.light,
                home: const _SessionRestoreSplash(),
              );
            }
            final authCubit = context.read<AuthCubit>();
            return MaterialApp.router(
              title: title,
              debugShowCheckedModeBanner: false,
              theme: CostikStudioTheme.light,
              routerConfig: createAppRouter(
                experience,
                authCubit: authCubit,
                authState: authState,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SessionRestoreSplash extends StatelessWidget {
  const _SessionRestoreSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

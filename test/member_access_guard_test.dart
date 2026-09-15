import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/router/app_router.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/product_detail/view/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('subscription pages redirect unauthenticated users to login', (
    tester,
  ) async {
    final router = createAppRouter(AppExperience.user);
    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => AuthCubit(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go('/products/costik-iptv/subscribe');
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.toString(), '/login');
  });

  testWidgets(
    'product detail hides download app before subscription status exists',
    (tester) async {
      final product = findProductById('smart-inv');

      await tester.pumpWidget(
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(),
          child: MaterialApp(home: ProductDetailPage(product: product)),
        ),
      );

      expect(find.text('Download app'), findsNothing);
      expect(find.text('Login untuk berlangganan'), findsOneWidget);
    },
  );
}

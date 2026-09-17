import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/product_detail/view/product_detail_page.dart';
import 'package:costikstudio/features/products/cubit/product_catalog_cubit.dart';
import 'package:costikstudio/features/shared/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('IPTV product card does not show the demo button', (
    tester,
  ) async {
    final product = findProductById('costik-iptv')!;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProductCard(product: product)),
      ),
    );

    expect(find.widgetWithText(OutlinedButton, 'Demo'), findsNothing);
  });

  testWidgets('public IPTV product detail stays informational only', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final product = findProductById('costik-iptv')!;
    final authCubit = AuthCubit();
    await authCubit.login('user@costik.com', '123456');

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<ProductCatalogCubit>(
            create: (_) => ProductCatalogCubit(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: ProductDetailPage(product: product)),
        ),
      ),
    );

    expect(find.text('Costik IPTV'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Demo'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Download APK'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Open web admin'), findsNothing);

    await authCubit.close();
  });
}

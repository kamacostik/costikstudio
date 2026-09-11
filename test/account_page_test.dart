import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:costikstudio/features/account/view/account_page.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_login_helper.dart';

void main() {
  testWidgets('renders account page with profile and billing sections', (
    tester,
  ) async {
    final authCubit = AuthCubit();
    await authCubit.login('user@costik.com', '123456');

    await tester.pumpWidget(
      BlocProvider.value(
        value: authCubit,
        child: const MaterialApp(home: Scaffold(body: AccountPage())),
      ),
    );

    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('user@costik.com'), findsWidgets);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Company Profile'), findsOneWidget);
    expect(find.text('Billing Contact'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
  });

  testWidgets('header exposes account page after login', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await loginAsCustomer(tester);

    expect(find.byKey(const Key('header_nav_/account')), findsOneWidget);
    await tester.tap(find.byKey(const Key('header_nav_/account')));
    await tester.pumpAndSettle();

    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('user@costik.com'), findsWidgets);
  });
}

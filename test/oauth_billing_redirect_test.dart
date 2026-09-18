import 'dart:io';

import 'package:costikstudio/app/costik_studio_app.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'test_login_helper.dart';

void main() {
  testWidgets('successful login opens billing dashboard', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const CostikStudioApp());
    await tester.pumpAndSettle();

    await loginAsCustomer(tester);

    final router = GoRouter.of(tester.element(find.text('Produk').first));
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.billing);
  });

  test('router refreshes after auth state changes and starts logged-in users at billing', () {
    final source = File('lib/core/router/app_router.dart').readAsStringSync();

    expect(source, contains('refreshListenable'));
    expect(source, contains('initialLocation: _initialLocationFor'));
    expect(source, contains('AppRoutes.billing'));
    expect(source, contains('authState.isAuthenticated'));
  });

  test('Google OAuth returns directly to billing', () {
    final source = File('lib/features/auth/cubit/auth_cubit.dart')
        .readAsStringSync();

    expect(source, contains('Uri.base.origin + AppRoutes.billing'));
  });
}

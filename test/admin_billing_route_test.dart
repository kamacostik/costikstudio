import 'package:costikstudio/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines admin billing route constants', () {
    expect(AppRoutes.adminBilling, '/admin/billing');
    expect(AppRouteNames.adminBilling, 'admin-billing');
  });
}

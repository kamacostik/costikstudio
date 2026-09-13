import 'package:costikstudio/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines admin dashboard and signage route constants', () {
    expect(AppRoutes.adminDashboard, '/admin/dashboard');
    expect(AppRouteNames.adminDashboard, 'admin-dashboard');
    expect(AppRoutes.adminSignage, '/admin/signage');
    expect(AppRouteNames.adminSignage, 'admin-signage');
  });
}

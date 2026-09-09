import 'package:costikstudio/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines billing route constants', () {
    expect(AppRoutes.billing, '/billing');
    expect(AppRouteNames.billing, 'billing');
  });
}

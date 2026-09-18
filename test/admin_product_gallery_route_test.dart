import 'package:costikstudio/core/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defines admin product gallery route constants', () {
    expect(AppRoutes.adminProductGallery, '/admin/product-gallery');
    expect(AppRouteNames.adminProductGallery, 'admin-product-gallery');
  });
}

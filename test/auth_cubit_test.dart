import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthCubit', () {
    test('starts with default customer role', () {
      final cubit = AuthCubit();
      expect(cubit.state.role, AuthRole.customer);
      expect(cubit.state.isCustomer, isTrue);
      expect(cubit.state.isAdmin, isFalse);
    });

    test('switches role between customer and admin', () {
      final cubit = AuthCubit();

      cubit.switchRole(AuthRole.admin);
      expect(cubit.state.role, AuthRole.admin);
      expect(cubit.state.isAdmin, isTrue);

      cubit.switchRole(AuthRole.customer);
      expect(cubit.state.role, AuthRole.customer);
      expect(cubit.state.isCustomer, isTrue);
    });
  });
}

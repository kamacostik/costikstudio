import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthCubit with Login/Logout', () {
    test('starts unauthenticated', () {
      final cubit = AuthCubit();
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.userEmail, isNull);
    });

    test('login as customer user successfully', () {
      final cubit = AuthCubit();

      final success = cubit.login('user@costik.com', '123456');

      expect(success, isTrue);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userEmail, 'user@costik.com');
      expect(cubit.state.role, AuthRole.customer);
    });

    test('login as admin user successfully', () {
      final cubit = AuthCubit();

      final success = cubit.login('admin@costik.com', '123456');

      expect(success, isTrue);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userEmail, 'admin@costik.com');
      expect(cubit.state.role, AuthRole.admin);
    });

    test('login fails with wrong password', () {
      final cubit = AuthCubit();

      final success = cubit.login('admin@costik.com', 'wrongpass');

      expect(success, isFalse);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('logout resets auth state', () {
      final cubit = AuthCubit();
      cubit.login('admin@costik.com', '123456');

      cubit.logout();

      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.userEmail, isNull);
    });
  });
}

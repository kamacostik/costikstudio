import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthCubit with Login/Logout', () {
    tearDown(() => SupabaseConfig.load(const {}));

    test('starts unauthenticated', () {
      final cubit = AuthCubit();
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.userEmail, isNull);
    });

    test('dummy fallback login as customer user successfully', () async {
      SupabaseConfig.load(const {});
      final cubit = AuthCubit();

      final success = await cubit.login('user@costik.com', '123456');

      expect(success, isTrue);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userEmail, 'user@costik.com');
      expect(cubit.state.role, AuthRole.customer);
    });

    test('dummy fallback login as admin user successfully', () async {
      SupabaseConfig.load(const {});
      final cubit = AuthCubit();

      final success = await cubit.login('admin@costik.com', '123456');

      expect(success, isTrue);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userEmail, 'admin@costik.com');
      expect(cubit.state.role, AuthRole.admin);
    });

    test('login fails with wrong password', () async {
      SupabaseConfig.load(const {});
      final cubit = AuthCubit();

      final success = await cubit.login('admin@costik.com', 'wrongpass');

      expect(success, isFalse);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('logout resets auth state', () async {
      SupabaseConfig.load(const {});
      final cubit = AuthCubit();
      await cubit.login('admin@costik.com', '123456');

      await cubit.logout();

      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.userEmail, isNull);
    });

    test(
      'google login without supabase config shows configuration error',
      () async {
        SupabaseConfig.load(const {});
        final cubit = AuthCubit();

        final success = await cubit.loginWithGoogle();

        expect(success, isFalse);
        expect(cubit.state.isAuthenticated, isFalse);
        expect(cubit.state.errorMessage, contains('Supabase'));
        await cubit.close();
      },
    );
  });
}

import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthRole { customer, admin }

class AuthState extends Equatable {
  const AuthState({
    this.isAuthenticated = false,
    this.role = AuthRole.customer,
    this.userEmail,
    this.isLoading = false,
    this.errorMessage,
  });

  final bool isAuthenticated;
  final AuthRole role;
  final String? userEmail;
  final bool isLoading;
  final String? errorMessage;

  bool get isCustomer => role == AuthRole.customer;
  bool get isAdmin => role == AuthRole.admin;

  AuthState copyWith({
    bool? isAuthenticated,
    AuthRole? role,
    String? userEmail,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      role: role ?? this.role,
      userEmail: userEmail ?? this.userEmail,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isAuthenticated,
    role,
    userEmail,
    isLoading,
    errorMessage,
  ];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({this.supabaseClient}) : super(const AuthState());

  final SupabaseClient? supabaseClient;

  SupabaseClient get _supabase => supabaseClient ?? Supabase.instance.client;

  Future<void> restoreSession() async {
    if (!SupabaseConfig.isConfigured) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final role = await _loadRole(user.id);
    emit(AuthState(isAuthenticated: true, role: role, userEmail: user.email));
  }

  Future<bool> login(String email, String password) async {
    emit(state.copyWith(isLoading: true));

    if (!SupabaseConfig.isConfigured) {
      return _loginWithDummyFallback(email, password);
    }

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        emit(
          const AuthState(errorMessage: 'Login gagal. User tidak ditemukan.'),
        );
        return false;
      }

      final role = await _loadRole(user.id);
      emit(AuthState(isAuthenticated: true, role: role, userEmail: user.email));
      return true;
    } on AuthException catch (error) {
      emit(AuthState(errorMessage: error.message));
      return false;
    } on Object {
      emit(const AuthState(errorMessage: 'Login Supabase gagal.'));
      return false;
    }
  }

  Future<void> logout() async {
    if (SupabaseConfig.isConfigured) {
      await _supabase.auth.signOut();
    }
    emit(const AuthState(isAuthenticated: false));
  }

  Future<AuthRole> _loadRole(String userId) async {
    final row = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    return row?['role'] == 'admin' ? AuthRole.admin : AuthRole.customer;
  }

  Future<bool> _loginWithDummyFallback(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (password != '123456') {
      emit(const AuthState(errorMessage: 'Email atau password salah.'));
      return false;
    }

    if (cleanEmail == 'admin@costik.com') {
      emit(
        AuthState(
          isAuthenticated: true,
          role: AuthRole.admin,
          userEmail: cleanEmail,
        ),
      );
      return true;
    }

    if (cleanEmail == 'user@costik.com' || cleanEmail.contains('@')) {
      emit(
        AuthState(
          isAuthenticated: true,
          role: AuthRole.customer,
          userEmail: cleanEmail,
        ),
      );
      return true;
    }

    emit(const AuthState(errorMessage: 'Email atau password salah.'));
    return false;
  }
}

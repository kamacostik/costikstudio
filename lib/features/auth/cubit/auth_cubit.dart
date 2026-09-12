import 'dart:async';

import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

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
  AuthCubit({this.supabaseClient}) : super(const AuthState()) {
    // On web, Google OAuth navigates the whole page away and back;
    // the session event completes the login in the fresh app instance.
    if (SupabaseConfig.isConfigured) {
      _authSubscription = _supabase.auth.onAuthStateChange.listen(
        _handleAuthEvent,
      );
    }
  }

  final sb.SupabaseClient? supabaseClient;

  sb.SupabaseClient get _supabase =>
      supabaseClient ?? sb.Supabase.instance.client;

  StreamSubscription<sb.AuthState>? _authSubscription;

  Future<void> _handleAuthEvent(sb.AuthState data) async {
    final session = data.session;
    if (data.event == sb.AuthChangeEvent.signedOut || session == null) {
      if (data.event == sb.AuthChangeEvent.signedOut && !isClosed) {
        emit(const AuthState(isAuthenticated: false));
      }
      return;
    }

    if (data.event == sb.AuthChangeEvent.signedIn ||
        data.event == sb.AuthChangeEvent.initialSession ||
        data.event == sb.AuthChangeEvent.tokenRefreshed) {
      final user = session.user;
      await _ensureProfile(user);
      if (isClosed) return;
      final role = await _loadRole(user.id);
      if (isClosed) return;
      emit(AuthState(isAuthenticated: true, role: role, userEmail: user.email));
    }
  }

  Future<void> restoreSession() async {
    if (!SupabaseConfig.isConfigured) return;

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _ensureProfile(user);
    if (isClosed) return;
    final role = await _loadRole(user.id);
    if (isClosed) return;
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

      await _ensureProfile(user);
      final role = await _loadRole(user.id);
      emit(AuthState(isAuthenticated: true, role: role, userEmail: user.email));
      return true;
    } on sb.AuthException catch (error) {
      emit(AuthState(errorMessage: error.message));
      return false;
    } on Object {
      emit(const AuthState(errorMessage: 'Login Supabase gagal.'));
      return false;
    }
  }

  /// Starts Google OAuth login on web.
  ///
  /// Returns true when the browser was redirected to Google; the actual
  /// session arrives via [onAuthStateChange] after Supabase redirects back
  /// to the app, so callers must not navigate on success.
  Future<bool> loginWithGoogle() async {
    if (!SupabaseConfig.isConfigured) {
      emit(
        const AuthState(
          errorMessage: 'Login Google membutuhkan konfigurasi Supabase.',
        ),
      );
      return false;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final launched = await _supabase.auth.signInWithOAuth(
        sb.OAuthProvider.google,
      );
      if (!launched) {
        emit(
          const AuthState(
            errorMessage: 'Login Google gagal dibuka. Coba lagi.',
          ),
        );
        return false;
      }
      return true;
    } on sb.AuthException catch (error) {
      emit(AuthState(errorMessage: error.message));
      return false;
    } on Object {
      emit(const AuthState(errorMessage: 'Login Google gagal.'));
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

  /// Ensures OAuth users (e.g. first-time Google login) have a profile row
  /// so role lookup and RLS-scoped reads keep working.
  Future<void> _ensureProfile(sb.User user) async {
    try {
      final metadata = user.userMetadata ?? const <String, dynamic>{};
      final fullName = (metadata['full_name'] ?? metadata['name'] ?? '')
          .toString()
          .trim();
      await _supabase.from('profiles').upsert({
        'id': user.id,
        if (fullName.isNotEmpty) 'full_name': fullName,
      });
    } on Object {
      // Never block login on a profile backfill; it retries on the next
      // session event.
    }
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

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}

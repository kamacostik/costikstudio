import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthRole { customer, admin }

class AuthState extends Equatable {
  const AuthState({
    this.isAuthenticated = false,
    this.role = AuthRole.customer,
    this.userEmail,
  });

  final bool isAuthenticated;
  final AuthRole role;
  final String? userEmail;

  bool get isCustomer => role == AuthRole.customer;
  bool get isAdmin => role == AuthRole.admin;

  @override
  List<Object?> get props => [isAuthenticated, role, userEmail];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  bool login(String email, String password) {
    final cleanEmail = email.trim().toLowerCase();
    if (password != '123456') {
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

    return false;
  }

  void logout() {
    emit(const AuthState(isAuthenticated: false));
  }
}

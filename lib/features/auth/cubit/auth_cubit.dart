import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthRole { customer, admin }

class AuthState extends Equatable {
  const AuthState({this.role = AuthRole.customer});

  final AuthRole role;

  bool get isCustomer => role == AuthRole.customer;
  bool get isAdmin => role == AuthRole.admin;

  @override
  List<Object?> get props => [role];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState());

  void switchRole(AuthRole role) {
    emit(AuthState(role: role));
  }

  void toggleRole() {
    emit(AuthState(role: state.isAdmin ? AuthRole.customer : AuthRole.admin));
  }
}

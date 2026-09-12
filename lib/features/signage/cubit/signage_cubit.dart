import 'package:costikstudio/features/signage/data/signage_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignageState extends Equatable {
  const SignageState({this.isLoading = false, this.tenant, this.errorMessage});

  final bool isLoading;
  final SignageTenant? tenant;
  final String? errorMessage;

  SignageState copyWith({
    bool? isLoading,
    SignageTenant? tenant,
    String? errorMessage,
  }) {
    return SignageState(
      isLoading: isLoading ?? this.isLoading,
      tenant: tenant ?? this.tenant,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, tenant, errorMessage];
}

class SignageCubit extends Cubit<SignageState> {
  SignageCubit({required this.repository}) : super(const SignageState());

  final SignageRepository repository;

  Future<void> loadTenant() async {
    emit(state.copyWith(isLoading: true));
    try {
      final tenant = await repository.fetchCurrentTenant();
      emit(SignageState(tenant: tenant));
    } catch (error) {
      emit(SignageState(tenant: state.tenant, errorMessage: error.toString()));
    }
  }

  Future<void> provisionTenant() async {
    emit(state.copyWith(isLoading: true));
    try {
      final tenant = await repository.provisionTenant();
      emit(SignageState(tenant: tenant));
    } catch (error) {
      emit(SignageState(tenant: state.tenant, errorMessage: error.toString()));
    }
  }
}

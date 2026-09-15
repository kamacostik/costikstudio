import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:costikstudio/features/signage/admin/admin_signage_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AdminSignageStatus { initial, loading, success, failure }

class AdminSignageState extends Equatable {
  const AdminSignageState({
    this.status = AdminSignageStatus.initial,
    this.tenants = const [],
    this.errorMessage,
  });

  final AdminSignageStatus status;
  final List<AdminSignageTenant> tenants;
  final String? errorMessage;

  AdminSignageState copyWith({
    AdminSignageStatus? status,
    List<AdminSignageTenant>? tenants,
    String? errorMessage,
  }) {
    return AdminSignageState(
      status: status ?? this.status,
      tenants: tenants ?? this.tenants,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, tenants, errorMessage];
}

class AdminSignageCubit extends Cubit<AdminSignageState> {
  AdminSignageCubit({AdminSignageRepository? repository})
    : _repository =
          repository ??
          (SupabaseConfig.isConfigured
              ? const SupabaseAdminSignageRepository()
              : DummyAdminSignageRepository()),
      super(const AdminSignageState());

  final AdminSignageRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: AdminSignageStatus.loading));
    try {
      final tenants = await _repository.loadTenants();
      emit(
        AdminSignageState(
          status: AdminSignageStatus.success,
          tenants: tenants,
        ),
      );
    } catch (error) {
      emit(
        AdminSignageState(
          status: AdminSignageStatus.failure,
          tenants: state.tenants,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

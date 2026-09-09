import 'package:costikstudio/features/billing/admin/admin_billing_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AdminBillingStatus { initial, loading, success, failure }

class AdminBillingState extends Equatable {
  const AdminBillingState({
    this.status = AdminBillingStatus.initial,
    this.snapshot,
    this.errorMessage,
  });

  final AdminBillingStatus status;
  final AdminBillingSnapshot? snapshot;
  final String? errorMessage;

  AdminBillingState copyWith({
    AdminBillingStatus? status,
    AdminBillingSnapshot? snapshot,
    String? errorMessage,
  }) {
    return AdminBillingState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, errorMessage];
}

class AdminBillingCubit extends Cubit<AdminBillingState> {
  AdminBillingCubit({required this.repository})
    : super(const AdminBillingState());

  final AdminBillingRepository repository;

  Future<void> load() async {
    emit(state.copyWith(status: AdminBillingStatus.loading));
    try {
      final snapshot = await repository.loadSnapshot();
      emit(
        AdminBillingState(
          status: AdminBillingStatus.success,
          snapshot: snapshot,
        ),
      );
    } catch (error) {
      emit(
        AdminBillingState(
          status: AdminBillingStatus.failure,
          snapshot: state.snapshot,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> approveTopUp(String topUpId) async {
    emit(state.copyWith(status: AdminBillingStatus.loading));
    try {
      final snapshot = await repository.approveTopUp(topUpId);
      emit(
        AdminBillingState(
          status: AdminBillingStatus.success,
          snapshot: snapshot,
        ),
      );
    } catch (error) {
      emit(
        AdminBillingState(
          status: AdminBillingStatus.failure,
          snapshot: state.snapshot,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

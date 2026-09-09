import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum BillingStatus { initial, loading, success, failure }

class BillingState extends Equatable {
  const BillingState({
    this.status = BillingStatus.initial,
    this.snapshot,
    this.errorMessage,
  });

  final BillingStatus status;
  final BillingSnapshot? snapshot;
  final String? errorMessage;

  BillingState copyWith({
    BillingStatus? status,
    BillingSnapshot? snapshot,
    String? errorMessage,
  }) {
    return BillingState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, errorMessage];
}

class BillingCubit extends Cubit<BillingState> {
  BillingCubit({required this.repository}) : super(const BillingState());

  final BillingRepository repository;

  Future<void> load() async {
    emit(state.copyWith(status: BillingStatus.loading));
    try {
      final snapshot = await repository.loadSnapshot();
      emit(BillingState(status: BillingStatus.success, snapshot: snapshot));
    } catch (error) {
      emit(
        BillingState(
          status: BillingStatus.failure,
          snapshot: state.snapshot,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> topUpDummy() async {
    await _runMutation(() => repository.topUp(amount: 100000));
  }

  void clearMessage() {
    if (state.snapshot != null && state.snapshot!.message != null) {
      emit(
        state.copyWith(
          snapshot: BillingSnapshot(
            wallet: state.snapshot!.wallet,
            products: state.snapshot!.products,
            plans: state.snapshot!.plans,
            subscriptions: state.snapshot!.subscriptions,
            transactions: state.snapshot!.transactions,
            invoices: state.snapshot!.invoices,
            message: null,
          ),
        ),
      );
    }
  }

  Future<void> checkoutPlan(String planId) async {
    await _runMutation(() => repository.checkoutPlan(planId: planId));
  }

  Future<void> _runMutation(Future<BillingSnapshot> Function() action) async {
    emit(state.copyWith(status: BillingStatus.loading));
    try {
      final snapshot = await action();
      emit(BillingState(status: BillingStatus.success, snapshot: snapshot));
    } catch (error) {
      emit(
        BillingState(
          status: BillingStatus.failure,
          snapshot: state.snapshot,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

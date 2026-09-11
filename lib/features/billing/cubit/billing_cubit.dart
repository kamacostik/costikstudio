import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/billing/topup_order_result.dart';
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
    await topUp(amount: 100000);
  }

  Future<TopUpOrderResult?> topUp({required int amount}) async {
    emit(state.copyWith(status: BillingStatus.loading));
    try {
      final order = await repository.topUp(amount: amount);
      final snapshot = await repository.loadSnapshot();
      emit(
        BillingState(
          status: BillingStatus.success,
          snapshot: BillingSnapshot(
            wallet: snapshot.wallet,
            products: snapshot.products,
            plans: snapshot.plans,
            subscriptions: snapshot.subscriptions,
            transactions: snapshot.transactions,
            invoices: snapshot.invoices,
            paymentOrders: snapshot.paymentOrders,
            message: order == null
                ? 'Top up request dibuat. Saldo masuk setelah webhook sukses.'
                : 'Payment order ${order.externalReference} dibuat untuk ${order.amount}.',
          ),
        ),
      );
      return order;
    } catch (error) {
      emit(
        BillingState(
          status: BillingStatus.failure,
          snapshot: state.snapshot,
          errorMessage: error.toString(),
        ),
      );
      return null;
    }
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
            paymentOrders: state.snapshot!.paymentOrders,
            message: null,
          ),
        ),
      );
    }
  }

  Future<void> checkoutPlan(String planId) async {
    await _runMutation(() => repository.checkoutPlan(planId: planId));
  }

  Future<void> checkoutIptvSubscription({
    required int deviceCount,
    required int billingCycleMonths,
  }) async {
    await _runMutation(
      () => repository.checkoutIptvSubscription(
        deviceCount: deviceCount,
        billingCycleMonths: billingCycleMonths,
      ),
    );
  }

  Future<void> renewIptvSubscription({
    required String subscriptionId,
    required int billingCycleMonths,
  }) async {
    await _runMutation(
      () => repository.renewIptvSubscription(
        subscriptionId: subscriptionId,
        billingCycleMonths: billingCycleMonths,
      ),
    );
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

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/features/billing/billing_dependencies.dart';
import 'package:costikstudio/features/billing/cubit/billing_cubit.dart';
import 'package:costikstudio/features/billing/widgets/billing_notice.dart';
import 'package:costikstudio/features/billing/widgets/invoices_card.dart';
import 'package:costikstudio/features/billing/widgets/plan_catalog_card.dart';
import 'package:costikstudio/features/billing/widgets/subscriptions_card.dart';
import 'package:costikstudio/features/billing/widgets/transactions_card.dart';
import 'package:costikstudio/features/billing/widgets/wallet_card.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BillingDashboardPage extends StatelessWidget {
  const BillingDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          BillingCubit(repository: createBillingRepository())..load(),
      child: const _BillingDashboardView(),
    );
  }
}

class _BillingDashboardView extends StatelessWidget {
  const _BillingDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillingCubit, BillingState>(
      builder: (context, state) {
        final snapshot = state.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          child: ResponsiveSection(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Billing Core',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Dummy wallet, plans, and subscriptions first. Later this layer can move to Supabase Edge Functions safely.',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: CostikStudioTheme.slate, height: 1.5),
                ),
                const SizedBox(height: 28),
                if (snapshot.message != null) ...[
                  BillingNotice(message: snapshot.message!),
                  const SizedBox(height: 18),
                ],
                _BillingTopSection(snapshot: snapshot),
                const SizedBox(height: 22),
                _BillingActivitySection(snapshot: snapshot),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BillingTopSection extends StatelessWidget {
  const _BillingTopSection({required this.snapshot});

  final BillingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WalletCard(
                balance: snapshot.wallet.balance,
                onTopUp: context.read<BillingCubit>().topUpDummy,
              ),
              const SizedBox(height: 18),
              PlanCatalogCard(
                products: snapshot.products,
                plans: snapshot.plans,
                subscriptions: snapshot.subscriptions,
                onSubscribe: (plan) => _checkout(context, plan),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: WalletCard(
                balance: snapshot.wallet.balance,
                onTopUp: context.read<BillingCubit>().topUpDummy,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 6,
              child: PlanCatalogCard(
                products: snapshot.products,
                plans: snapshot.plans,
                subscriptions: snapshot.subscriptions,
                onSubscribe: (plan) => _checkout(context, plan),
              ),
            ),
          ],
        );
      },
    );
  }

  void _checkout(BuildContext context, BillingPlan plan) {
    context.read<BillingCubit>().checkoutPlan(plan.id);
  }
}

class _BillingActivitySection extends StatelessWidget {
  const _BillingActivitySection({required this.snapshot});

  final BillingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SubscriptionsCard(
                products: snapshot.products,
                plans: snapshot.plans,
                subscriptions: snapshot.subscriptions,
              ),
              const SizedBox(height: 18),
              TransactionsCard(transactions: snapshot.transactions),
              const SizedBox(height: 18),
              InvoicesCard(invoices: snapshot.invoices),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SubscriptionsCard(
                products: snapshot.products,
                plans: snapshot.plans,
                subscriptions: snapshot.subscriptions,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                children: [
                  TransactionsCard(transactions: snapshot.transactions),
                  const SizedBox(height: 18),
                  InvoicesCard(invoices: snapshot.invoices),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/features/billing/widgets/billing_history_table_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Riwayat & Log includes failed payment orders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BillingHistoryTableCard(
            transactions: const [
              WalletTransaction(
                userId: 'demo-user',
                type: WalletTransactionType.purchase,
                amount: 15000,
                balanceBefore: 50000,
                balanceAfter: 35000,
                referenceId: 'checkout:ok',
              ),
            ],
            invoices: const [],
            paymentOrders: [
              PaymentOrder(
                id: 'order-failed-1',
                externalReference: 'TOPUP-FAILED-001',
                amount: 50000,
                status: 'failed',
                provider: 'sumopod',
                paymentMethodTypeCode: 'QRIS',
                createdAt: DateTime(2026, 9, 11),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Riwayat & Log'), findsOneWidget);

    await tester.tap(find.text('Top Up'));
    await tester.pumpAndSettle();

    expect(find.text('TOPUP-FAILED-001'), findsOneWidget);
    expect(find.text('Gagal'), findsOneWidget);
    expect(find.text('+ Rp 50.000'), findsOneWidget);
  });
}

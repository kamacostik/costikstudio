import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Billing invoice', () {
    test('creates paid invoice from wallet purchase transaction', () {
      const transaction = WalletTransaction(
        userId: 'demo-user',
        type: WalletTransactionType.purchase,
        amount: 150000,
        balanceBefore: 350000,
        balanceAfter: 200000,
        referenceId: 'checkout:costik-signage:signage-pro',
      );
      final issuedAt = DateTime(2026, 9, 9);

      final invoice = BillingInvoice.fromWalletTransaction(
        transaction: transaction,
        number: 'INV-20260909-001',
        issuedAt: issuedAt,
      );

      expect(invoice.number, 'INV-20260909-001');
      expect(invoice.userId, 'demo-user');
      expect(invoice.type, BillingInvoiceType.subscription);
      expect(invoice.status, BillingInvoiceStatus.paid);
      expect(invoice.amount, 150000);
      expect(invoice.issuedAt, issuedAt);
      expect(invoice.paidAt, issuedAt);
    });

    test('creates paid invoice from wallet top up transaction', () {
      const transaction = WalletTransaction(
        userId: 'demo-user',
        type: WalletTransactionType.topup,
        amount: 100000,
        balanceBefore: 350000,
        balanceAfter: 450000,
        referenceId: 'dummy-topup-100000',
      );

      final invoice = BillingInvoice.fromWalletTransaction(
        transaction: transaction,
        number: 'INV-20260909-002',
        issuedAt: DateTime(2026, 9, 9),
      );

      expect(invoice.type, BillingInvoiceType.topup);
      expect(invoice.status, BillingInvoiceStatus.paid);
      expect(invoice.amount, 100000);
    });
  });
}

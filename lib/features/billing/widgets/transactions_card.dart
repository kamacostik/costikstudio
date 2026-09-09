import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:flutter/material.dart';

class TransactionsCard extends StatelessWidget {
  const TransactionsCard({super.key, required this.transactions});

  final List<WalletTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent wallet activity',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (final transaction in transactions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  transaction.type == WalletTransactionType.topup
                      ? Icons.add_circle_rounded
                      : Icons.remove_circle_rounded,
                  color: transaction.type == WalletTransactionType.topup
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text(
                  transaction.type == WalletTransactionType.topup
                      ? 'Dummy top up'
                      : 'Plan purchase',
                ),
                subtitle: Text(transaction.referenceId),
                trailing: Text(
                  formatRupiah(transaction.amount),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

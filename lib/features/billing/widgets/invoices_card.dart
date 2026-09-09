import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:flutter/material.dart';

class InvoicesCard extends StatelessWidget {
  const InvoicesCard({super.key, required this.invoices});

  final List<BillingInvoice> invoices;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoices',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (final invoice in invoices.take(4))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.receipt_long_rounded,
                  color: CostikStudioTheme.primary,
                ),
                title: Text(invoice.number),
                subtitle: Text(
                  invoice.type == BillingInvoiceType.topup
                      ? 'Top up wallet'
                      : 'Subscription payment',
                ),
                trailing: Chip(
                  label: Text(
                    invoice.status == BillingInvoiceStatus.paid
                        ? 'Paid ${formatRupiah(invoice.amount)}'
                        : 'Draft',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

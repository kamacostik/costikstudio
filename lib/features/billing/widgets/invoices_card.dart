import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/platform/web_print.dart';
import 'package:flutter/material.dart';

class InvoicesCard extends StatelessWidget {
  const InvoicesCard({super.key, required this.invoices});

  final List<BillingInvoice> invoices;

  void _showInvoiceDetails(BuildContext context, BillingInvoice invoice) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              color: CostikStudioTheme.primary,
            ),
            const SizedBox(width: 8),
            Text('Invoice ${invoice.number}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InvoiceDetailRow(label: 'Nomor Invoice', value: invoice.number),
            _InvoiceDetailRow(
              label: 'Tipe',
              value: invoice.type == BillingInvoiceType.topup
                  ? 'Top up wallet'
                  : 'Subscription payment',
            ),
            _InvoiceDetailRow(
              label: 'Total Bayar',
              value: formatRupiah(invoice.amount),
            ),
            _InvoiceDetailRow(
              label: 'Status',
              value: invoice.status.name.toUpperCase(),
            ),
            _InvoiceDetailRow(
              label: 'Tanggal Terbit',
              value: _formatDate(invoice.issuedAt),
            ),
            if (invoice.paidAt != null)
              _InvoiceDetailRow(
                label: 'Tanggal Lunas',
                value: _formatDate(invoice.paidAt!),
              ),
            _InvoiceDetailRow(
              label: 'Reference ID',
              value: invoice.referenceId,
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: printCurrentPage,
            icon: const Icon(Icons.print_rounded, size: 16),
            label: const Text('Cetak / PDF'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

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
            if (invoices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Belum ada invoice.'),
              )
            else
              for (final invoice in invoices)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: CostikStudioTheme.background),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(
                      Icons.receipt_long_rounded,
                      color: CostikStudioTheme.primary,
                    ),
                    title: Text(
                      invoice.number,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      invoice.type == BillingInvoiceType.topup
                          ? 'Top up wallet'
                          : 'Subscription payment',
                    ),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            invoice.status == BillingInvoiceStatus.paid
                                ? 'Paid ${formatRupiah(invoice.amount)}'
                                : 'Draft',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showInvoiceDetails(context, invoice),
                          icon: const Icon(
                            Icons.remove_red_eye_rounded,
                            size: 16,
                          ),
                          label: const Text('View Details'),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceDetailRow extends StatelessWidget {
  const _InvoiceDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(
                color: CostikStudioTheme.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

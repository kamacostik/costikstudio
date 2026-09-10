import 'dart:convert';

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
      builder: (dialogCtx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InvoiceDocument(invoice: invoice),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Tutup'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => printHtmlDocument(
                        title: invoice.number,
                        htmlContent: _invoiceHtml(invoice),
                      ),
                      icon: const Icon(Icons.print_rounded, size: 16),
                      label: const Text('Print / Save PDF'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
                    subtitle: Text(_invoiceItemName(invoice)),
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

class _InvoiceDocument extends StatelessWidget {
  const _InvoiceDocument({required this.invoice});

  final BillingInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Costik Studio',
                      style: TextStyle(
                        color: CostikStudioTheme.navy,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Costik Digital Solutions',
                      style: TextStyle(color: CostikStudioTheme.slate),
                    ),
                    Text(
                      'Kendari, Indonesia',
                      style: TextStyle(color: CostikStudioTheme.slate),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'INVOICE',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: CostikStudioTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    invoice.number,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _InvoiceBox(
                  title: 'Bill To',
                  lines: ['Customer ID', invoice.userId],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InvoiceBox(
                  title: 'Invoice Info',
                  lines: [
                    'Issued: ${_formatDate(invoice.issuedAt)}',
                    'Paid: ${invoice.paidAt == null ? '-' : _formatDate(invoice.paidAt!)}',
                    'Status: ${invoice.status.name.toUpperCase()}',
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Table(
            border: TableBorder.all(color: const Color(0xFFE2E8F0)),
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1.3),
              3: FlexColumnWidth(1.3),
            },
            children: [
              _tableRow([
                'Item',
                'Qty',
                'Unit Price',
                'Amount',
              ], isHeader: true),
              _tableRow([
                _invoiceItemName(invoice),
                '1',
                formatRupiah(invoice.amount),
                formatRupiah(invoice.amount),
              ]),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 280,
              child: Column(
                children: [
                  _TotalRow(
                    label: 'Subtotal',
                    value: formatRupiah(invoice.amount),
                  ),
                  const Divider(),
                  _TotalRow(
                    label: 'Total Paid',
                    value: formatRupiah(invoice.amount),
                    isBold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Reference: ${invoice.referenceId}',
            style: const TextStyle(
              color: CostikStudioTheme.slate,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thank you for your payment. This invoice was generated automatically by Costik Studio Billing.',
            style: TextStyle(color: CostikStudioTheme.slate),
          ),
        ],
      ),
    );
  }
}

class _InvoiceBox extends StatelessWidget {
  const _InvoiceBox({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: CostikStudioTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            SelectableText(
              line,
              style: const TextStyle(color: CostikStudioTheme.slate),
            ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: CostikStudioTheme.slate,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: CostikStudioTheme.navy,
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

TableRow _tableRow(List<String> cells, {bool isHeader = false}) {
  return TableRow(
    decoration: BoxDecoration(
      color: isHeader ? const Color(0xFFF1F5F9) : Colors.white,
    ),
    children: [
      for (final cell in cells)
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            cell,
            style: TextStyle(
              color: CostikStudioTheme.navy,
              fontWeight: isHeader ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
        ),
    ],
  );
}

String _invoiceItemName(BillingInvoice invoice) {
  return invoice.type == BillingInvoiceType.topup
      ? 'Top up wallet'
      : 'Subscription payment';
}

String _formatDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _invoiceHtml(BillingInvoice invoice) {
  final status = invoice.status.name.toUpperCase();
  final item = _invoiceItemName(invoice);
  final number = const HtmlEscape().convert(invoice.number);
  final user = const HtmlEscape().convert(invoice.userId);
  final reference = const HtmlEscape().convert(invoice.referenceId);
  final issued = _formatDate(invoice.issuedAt);
  final paid = invoice.paidAt == null ? '-' : _formatDate(invoice.paidAt!);
  final amount = formatRupiah(invoice.amount);

  return '''
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <title>$number</title>
  <style>
    @page { size: A4; margin: 18mm; }
    * { box-sizing: border-box; }
    body { font-family: Arial, sans-serif; color: #0f172a; margin: 0; background: white; }
    .invoice { width: 100%; max-width: 760px; margin: 0 auto; }
    .header { display: flex; justify-content: space-between; gap: 24px; border-bottom: 2px solid #2563eb; padding-bottom: 24px; }
    .brand { font-size: 26px; font-weight: 800; }
    .muted { color: #475569; line-height: 1.6; }
    .title { text-align: right; }
    .title h1 { margin: 0; color: #2563eb; letter-spacing: 3px; font-size: 34px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; margin: 28px 0; }
    .box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 12px; padding: 16px; }
    .box h3 { margin: 0 0 8px; font-size: 14px; text-transform: uppercase; letter-spacing: .08em; }
    table { width: 100%; border-collapse: collapse; margin-top: 16px; }
    th { background: #f1f5f9; text-align: left; }
    th, td { border: 1px solid #e2e8f0; padding: 14px; }
    .right { text-align: right; }
    .total { width: 320px; margin-left: auto; margin-top: 22px; }
    .total-row { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #e2e8f0; }
    .grand { font-size: 20px; font-weight: 800; }
    .footer { margin-top: 36px; color: #475569; font-size: 13px; line-height: 1.7; }
    @media print { body { -webkit-print-color-adjust: exact; print-color-adjust: exact; } }
  </style>
</head>
<body>
  <main class="invoice">
    <section class="header">
      <div>
        <div class="brand">Costik Studio</div>
        <div class="muted">Costik Digital Solutions<br>Kendari, Indonesia</div>
      </div>
      <div class="title">
        <h1>INVOICE</h1>
        <div><strong>$number</strong></div>
      </div>
    </section>

    <section class="grid">
      <div class="box">
        <h3>Bill To</h3>
        <div class="muted">Customer ID<br><strong>$user</strong></div>
      </div>
      <div class="box">
        <h3>Invoice Info</h3>
        <div class="muted">Issued: $issued<br>Paid: $paid<br>Status: <strong>$status</strong></div>
      </div>
    </section>

    <table>
      <thead>
        <tr><th>Item</th><th>Qty</th><th class="right">Unit Price</th><th class="right">Amount</th></tr>
      </thead>
      <tbody>
        <tr><td>$item</td><td>1</td><td class="right">$amount</td><td class="right">$amount</td></tr>
      </tbody>
    </table>

    <section class="total">
      <div class="total-row"><span>Subtotal</span><strong>$amount</strong></div>
      <div class="total-row grand"><span>Total Paid</span><span>$amount</span></div>
    </section>

    <section class="footer">
      <div>Reference: $reference</div>
      <div>Thank you for your payment. This invoice was generated automatically by Costik Studio Billing.</div>
    </section>
  </main>
  <script>window.onload = function(){ window.focus(); window.print(); };</script>
</body>
</html>
''';
}

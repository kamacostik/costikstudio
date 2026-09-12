import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:flutter/material.dart';

enum _BillingSubTab { transactions, topup }

class BillingHistoryTableCard extends StatefulWidget {
  const BillingHistoryTableCard({
    super.key,
    required this.transactions,
    required this.invoices,
    this.paymentOrders = const [],
  });

  final List<WalletTransaction> transactions;
  final List<BillingInvoice> invoices;
  final List<PaymentOrder> paymentOrders;

  @override
  State<BillingHistoryTableCard> createState() =>
      _BillingHistoryTableCardState();
}

class _BillingHistoryTableCardState extends State<BillingHistoryTableCard> {
  _BillingSubTab _activeTab = _BillingSubTab.transactions;

  List<WalletTransaction> get _purchaseTransactions => widget.transactions
      .where((t) => t.type != WalletTransactionType.topup)
      .toList();

  List<WalletTransaction> get _topupTransactions => widget.transactions
      .where((t) => t.type == WalletTransactionType.topup)
      .toList();

  List<PaymentOrder> get _failedPaymentOrders => widget.paymentOrders
      .where((order) => _isFailedPaymentStatus(order.status))
      .toList();

  int get _topupLogCount =>
      _topupTransactions.length + _failedPaymentOrders.length;

  @override
  Widget build(BuildContext context) {
    final displayedList = _sortHistoryEntries(
      _activeTab == _BillingSubTab.transactions
          ? <Object>[..._purchaseTransactions]
          : <Object>[..._failedPaymentOrders, ..._topupTransactions],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Sub-Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat & Log',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: CostikStudioTheme.navy,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TabButton(
                        label: 'Transaksi',
                        icon: Icons.receipt_long_rounded,
                        count: _purchaseTransactions.length,
                        isSelected: _activeTab == _BillingSubTab.transactions,
                        onTap: () => setState(
                          () => _activeTab = _BillingSubTab.transactions,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _TabButton(
                        label: 'Top Up',
                        icon: Icons.add_card_rounded,
                        count: _topupLogCount,
                        isSelected: _activeTab == _BillingSubTab.topup,
                        onTap: () =>
                            setState(() => _activeTab = _BillingSubTab.topup),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Table Content
            if (displayedList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        _activeTab == _BillingSubTab.transactions
                            ? Icons.receipt_rounded
                            : Icons.account_balance_wallet_rounded,
                        size: 40,
                        color: CostikStudioTheme.slate.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _activeTab == _BillingSubTab.transactions
                            ? 'Belum ada data transaksi pembelian paket'
                            : 'Belum ada riwayat top-up saldo',
                        style: const TextStyle(color: CostikStudioTheme.slate),
                      ),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        headingRowColor: WidgetStatePropertyAll(
                          const Color(0xFFF8FAFC),
                        ),
                        horizontalMargin: 16,
                        columnSpacing: 24,
                        columns: const [
                          DataColumn(
                            label: Text(
                              'Tipe / Referensi',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Tanggal',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Kategori',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Nominal',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Saldo Sebelum',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Saldo Sesudah',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Status',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                        rows: [
                          for (final entry in displayedList)
                            _buildHistoryRow(entry),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  DataRow _buildHistoryRow(Object entry) {
    if (entry is PaymentOrder) {
      return _buildPaymentOrderRow(entry);
    }
    return _buildTransactionRow(entry as WalletTransaction);
  }

  DataRow _buildTransactionRow(WalletTransaction tx) {
    final isTopup = tx.type == WalletTransactionType.topup;
    final color = isTopup ? Colors.green : Colors.blue;
    return DataRow(
      cells: [
        DataCell(
          _ReferenceCell(
            icon: isTopup
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            iconColor: color,
            title: isTopup ? 'Top Up Saldo' : 'Pembayaran Paket',
            reference: tx.referenceId,
          ),
        ),
        DataCell(_DateCell(date: tx.createdAt)),
        DataCell(
          Text(
            tx.type.name.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            '${isTopup ? '+' : '-'} ${formatRupiah(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isTopup ? Colors.green.shade700 : CostikStudioTheme.navy,
            ),
          ),
        ),
        DataCell(
          Text(
            formatRupiah(tx.balanceBefore),
            style: const TextStyle(color: CostikStudioTheme.slate),
          ),
        ),
        DataCell(
          Text(
            formatRupiah(tx.balanceAfter),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(_StatusBadge(label: 'Berhasil', color: Colors.green)),
      ],
    );
  }

  DataRow _buildPaymentOrderRow(PaymentOrder order) {
    return DataRow(
      cells: [
        DataCell(
          _ReferenceCell(
            icon: Icons.error_outline_rounded,
            iconColor: Colors.red,
            title: 'Top Up Gagal',
            reference: order.externalReference,
          ),
        ),
        DataCell(_DateCell(date: order.createdAt)),
        DataCell(
          Text(
            'TOPUP ${order.provider.toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        DataCell(
          Text(
            '+ ${formatRupiah(order.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.red.shade700,
            ),
          ),
        ),
        const DataCell(
          Text('-', style: TextStyle(color: CostikStudioTheme.slate)),
        ),
        const DataCell(
          Text('-', style: TextStyle(color: CostikStudioTheme.slate)),
        ),
        DataCell(
          _StatusBadge(
            label: _paymentStatusLabel(order.status),
            color: Colors.red,
          ),
        ),
      ],
    );
  }

  List<Object> _sortHistoryEntries(List<Object> entries) {
    final sorted = [...entries];
    sorted.sort((a, b) => _entryDate(b).compareTo(_entryDate(a)));
    return sorted;
  }

  DateTime _entryDate(Object entry) {
    if (entry is WalletTransaction) {
      return entry.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (entry is PaymentOrder) return entry.createdAt;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _isFailedPaymentStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized == 'failed' ||
        normalized == 'cancelled' ||
        normalized == 'expired' ||
        normalized == 'error';
  }

  String _paymentStatusLabel(String status) {
    return switch (status.toLowerCase()) {
      'cancelled' => 'Dibatalkan',
      'expired' => 'Expired',
      _ => 'Gagal',
    };
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final value = date;
    if (value == null) {
      return const Text('-', style: TextStyle(color: CostikStudioTheme.slate));
    }

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$day/$month/$year',
          style: const TextStyle(
            color: CostikStudioTheme.navy,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        Text(
          '$hour:$minute',
          style: const TextStyle(color: CostikStudioTheme.slate, fontSize: 11),
        ),
      ],
    );
  }
}

class _ReferenceCell extends StatelessWidget {
  const _ReferenceCell({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.reference,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String reference;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            Text(
              reference,
              style: const TextStyle(
                fontSize: 11,
                color: CostikStudioTheme.slate,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? CostikStudioTheme.primary
                  : CostikStudioTheme.slate,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? CostikStudioTheme.navy
                    : CostikStudioTheme.slate,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? CostikStudioTheme.primary.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? CostikStudioTheme.primary
                      : CostikStudioTheme.slate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

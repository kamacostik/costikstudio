import 'dart:async';

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/billing/topup_order_result.dart';
import 'package:costikstudio/core/payment/payment_order_canceller.dart';
import 'package:costikstudio/core/platform/external_url.dart';
import 'package:costikstudio/features/billing/cubit/billing_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.balance,
    required this.onTopUp,
    this.paymentOrders = const [],
  });

  final int balance;
  final Future<TopUpOrderResult?> Function(int amount) onTopUp;
  final List<PaymentOrder> paymentOrders;

  List<PaymentOrder> get _pendingOrders =>
      paymentOrders.where((order) => order.isPending).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final pendingOrders = _pendingOrders;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: CostikStudioTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: CostikStudioTheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wallet balance',
                          style: TextStyle(
                            color: CostikStudioTheme.slate,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatRupiah(balance),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: CostikStudioTheme.navy,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => _showTopUpDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Top Up'),
                ),
              ],
            ),
            if (pendingOrders.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'Payment pending',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: CostikStudioTheme.navy,
                ),
              ),
              const SizedBox(height: 10),
              ...pendingOrders
                  .take(3)
                  .map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.pending_actions_rounded,
                              color: Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatRupiah(order.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: CostikStudioTheme.navy,
                                    ),
                                  ),
                                  Text(
                                    'Ref: ${order.externalReference}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: CostikStudioTheme.slate,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                if (order.hasPaymentUrl)
                                  FilledButton.icon(
                                    onPressed: () => _showPaymentQrDialog(
                                      context,
                                      title: 'Bayar Top Up',
                                      amount: order.amount,
                                      reference: order.externalReference,
                                      paymentUrl: order.paymentUrl!,
                                      order: TopUpOrderResult(
                                        orderId: order.id,
                                        externalReference:
                                            order.externalReference,
                                        status: order.status,
                                        amount: order.amount,
                                        paymentUrl: order.paymentUrl,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.qr_code_rounded,
                                      size: 14,
                                    ),
                                    label: const Text('Lihat QR'),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  )
                                else ...[
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Menunggu link bayar',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _showWaitingPaymentLinkDialog(
                                          context,
                                          TopUpOrderResult(
                                            orderId: order.id,
                                            externalReference:
                                                order.externalReference,
                                            status: order.status,
                                            amount: order.amount,
                                            paymentUrl: order.paymentUrl,
                                          ),
                                        ),
                                    icon: const Icon(
                                      Icons.tune_rounded,
                                      size: 14,
                                    ),
                                    label: const Text('Kelola'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                                TextButton.icon(
                                  onPressed: () => _cancelPendingOrder(
                                    context,
                                    order.externalReference,
                                  ),
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    size: 14,
                                  ),
                                  label: const Text('Batalkan'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showTopUpDialog(BuildContext context) async {
    final amount = await _askTopUpAmount(context);
    if (amount == null || !context.mounted) return;
    await _handleTopUpFlow(context, amount);
  }

  Future<void> _cancelPendingOrder(
    BuildContext context,
    String externalReference,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Transaksi?'),
        content: const Text(
          'Payment order pending ini akan dibatalkan. Setelah itu user bisa membuat top up baru dengan nominal berbeda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final cancelled = await const PaymentOrderCanceller()
        .cancelByExternalReference(externalReference);
    if (!context.mounted) return;
    if (cancelled) {
      await context.read<BillingCubit>().load();
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          cancelled
              ? 'Transaksi dibatalkan. Silakan buat top up baru.'
              : 'Belum bisa membatalkan transaksi ini.',
        ),
        backgroundColor: cancelled ? null : Colors.red,
      ),
    );
  }

  Future<int?> _askTopUpAmount(BuildContext context) async {
    final controller = TextEditingController(text: '100000');
    final formKey = GlobalKey<FormState>();
    final amount = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Top Up Wallet'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan nominal top-up. Saldo akan masuk setelah payment gateway mengirim webhook sukses.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nominal top-up',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = int.tryParse(value?.trim() ?? '');
                  if (amount == null || amount < 10000) {
                    return 'Minimal top-up Rp 10.000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [100000, 250000, 500000].map((preset) {
                  return ChoiceChip(
                    label: Text(formatRupiah(preset)),
                    selected: controller.text == '$preset',
                    onSelected: (_) {
                      controller.text = '$preset';
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(dialogContext)
                  .pop(int.parse(controller.text.trim()));
            },
            child: const Text('Buat Payment Order'),
          ),
        ],
      ),
    );
    return amount;
  }

  Future<void> _handleTopUpFlow(BuildContext context, int amount) async {
    // ignore: use_build_context_synchronously
    var currentAmount = amount;
    var retryTopUp = true;
    while (retryTopUp && context.mounted) {
      retryTopUp = false;
      // ignore: use_build_context_synchronously
      final result = await _createPaymentOrder(context, currentAmount);
      if (result == _TopUpDialogAction.retry) {
        if (!context.mounted) return;
        final nextAmount = await _askTopUpAmount(context);
        if (nextAmount == null) return;
        currentAmount = nextAmount;
        retryTopUp = true;
      }
    }
  }

  Future<_TopUpDialogAction?> _createPaymentOrder(
    BuildContext context,
    int amount,
  ) async {
    var loadingDialogShown = false;
    final loadingDelay = Future<void>.delayed(const Duration(milliseconds: 250))
        .then((_) {
          if (!context.mounted) return;
          loadingDialogShown = true;
          unawaited(_showPaymentLinkLoadingDialog(context, amount));
        });
    final order = await onTopUp(amount);
    await loadingDelay;
    if (!context.mounted) return null;
    if (loadingDialogShown) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (order != null && order.hasPaymentError && context.mounted) {
      return _showPaymentErrorDialog(context, order);
    }
    if (order != null && order.paymentUrl != null && context.mounted) {
      return _showPaymentQrDialog(
        context,
        title: 'Scan QRIS untuk Top Up',
        amount: order.amount,
        reference: order.externalReference,
        paymentUrl: order.paymentUrl!,
        order: order,
      );
    } else if (order != null && context.mounted) {
      return _showWaitingPaymentLinkDialog(context, order);
    } else if (context.mounted) {
      final errorMsg = context.read<BillingCubit>().state.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg != null && errorMsg.isNotEmpty ? 'Gagal: $errorMsg' : 'Gagal membuat payment order. Periksa koneksi/kredensial Supabase.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }

  Future<void> _showPaymentLinkLoadingDialog(BuildContext context, int amount) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
            const SizedBox(height: 18),
            Text(
              'Membuat link pembayaran',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: CostikStudioTheme.navy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${formatRupiah(amount)} sedang diproses ke Sumopod QRIS.',
              style: const TextStyle(color: CostikStudioTheme.slate),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<_TopUpDialogAction?> _showPaymentErrorDialog(
    BuildContext context,
    TopUpOrderResult order,
  ) {
    return showDialog<_TopUpDialogAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Link Pembayaran Gagal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.paymentErrorMessage ??
                  'n8n belum berhasil membuat link pembayaran.',
            ),
            const SizedBox(height: 16),
            _TopUpOrderRow(label: 'Reference', value: order.externalReference),
            _TopUpOrderRow(label: 'Nominal', value: formatRupiah(order.amount)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
          TextButton.icon(
            onPressed: () async {
              final cancelled = await const PaymentOrderCanceller()
                  .cancelByExternalReference(order.externalReference);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(_TopUpDialogAction.cancelled);
              if (cancelled && context.mounted) {
                await context.read<BillingCubit>().load();
              }
            },
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Batalkan'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await const PaymentOrderCanceller().cancelByExternalReference(
                order.externalReference,
              );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(_TopUpDialogAction.retry);
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Future<_TopUpDialogAction?> _showWaitingPaymentLinkDialog(
    BuildContext context,
    TopUpOrderResult order,
  ) {
    return showDialog<_TopUpDialogAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Menunggu Link Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment order sudah dibuat. Link QRIS sedang dibuat oleh Sumopod. Refresh Billing beberapa saat lagi bila belum muncul.',
            ),
            const SizedBox(height: 16),
            _TopUpOrderRow(label: 'Reference', value: order.externalReference),
            _TopUpOrderRow(label: 'Nominal', value: formatRupiah(order.amount)),
            const SizedBox(height: 12),
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Menunggu link bayar'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
          TextButton.icon(
            onPressed: () async {
              final cancelled = await const PaymentOrderCanceller()
                  .cancelByExternalReference(order.externalReference);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(_TopUpDialogAction.cancelled);
              if (cancelled && context.mounted) {
                await context.read<BillingCubit>().load();
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    cancelled
                        ? 'Transaksi dibatalkan. Silakan buat top up baru.'
                        : 'Belum bisa membatalkan transaksi ini.',
                  ),
                  backgroundColor: cancelled ? null : Colors.red,
                ),
              );
            },
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Batalkan Transaksi'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await const PaymentOrderCanceller().cancelByExternalReference(
                order.externalReference,
              );
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(_TopUpDialogAction.retry);
            },
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Buat Link Baru'),
          ),
        ],
      ),
    );
  }

  Future<_TopUpDialogAction?> _showPaymentQrDialog(
    BuildContext context, {
    required String title,
    required int amount,
    required String reference,
    required String paymentUrl,
    required TopUpOrderResult order,
  }) {
    return showDialog<_TopUpDialogAction>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: CostikStudioTheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: QrImageView(
                  data: paymentUrl,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                formatRupiah(amount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: CostikStudioTheme.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scan QRIS atau buka link pembayaran untuk menyelesaikan top up.',
                style: const TextStyle(color: CostikStudioTheme.slate),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              _TopUpOrderRow(label: 'Reference', value: reference),
              _TopUpOrderRow(label: 'Payment URL', value: paymentUrl),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tutup'),
          ),
          TextButton.icon(
            onPressed: () async {
              final cancelled = await const PaymentOrderCanceller()
                  .cancelByExternalReference(order.externalReference);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(_TopUpDialogAction.cancelled);
              if (cancelled && context.mounted) {
                await context.read<BillingCubit>().load();
              }
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    cancelled
                        ? 'Transaksi dibatalkan. Silakan buat top up baru.'
                        : 'Belum bisa membatalkan transaksi ini.',
                  ),
                  backgroundColor: cancelled ? null : Colors.red,
                ),
              );
            },
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Batalkan'),
          ),
          FilledButton.icon(
            onPressed: () => openExternalUrl(paymentUrl),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Buka Link Bayar'),
          ),
        ],
      ),
    );
  }
}

enum _TopUpDialogAction { retry, cancelled }

class _TopUpOrderRow extends StatelessWidget {
  const _TopUpOrderRow({required this.label, required this.value});

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
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                fontWeight: FontWeight.w700,
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

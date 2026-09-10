import 'dart:async';

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/billing/billing_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentReturnPage extends StatefulWidget {
  const PaymentReturnPage.success({super.key})
    : isSuccess = true,
      title = 'Pembayaran Diproses',
      description = 'Terima kasih. Kami sedang mengecek status pembayaran dan memperbarui saldo wallet.',
      icon = Icons.check_circle_rounded,
      color = Colors.green,
      autoRedirectDelay = const Duration(seconds: 5);

  const PaymentReturnPage.cancelled({super.key})
    : isSuccess = false,
      title = 'Pembayaran Dibatalkan',
      description = 'Pembayaran belum diselesaikan. Kamu akan diarahkan kembali ke Billing untuk membuat top up baru bila perlu.',
      icon = Icons.cancel_rounded,
      color = Colors.orange,
      autoRedirectDelay = const Duration(seconds: 4);

  final bool isSuccess;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Duration autoRedirectDelay;

  @override
  State<PaymentReturnPage> createState() => _PaymentReturnPageState();
}

class _PaymentReturnPageState extends State<PaymentReturnPage> {
  Timer? _redirectTimer;
  var _checkingStatus = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_checkPaymentStatus());
    _redirectTimer = Timer(widget.autoRedirectDelay, _goToBilling);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPaymentStatus() async {
    if (!widget.isSuccess) {
      setState(() => _statusMessage = 'Kembali ke Billing sebentar lagi.');
      return;
    }

    setState(() {
      _checkingStatus = true;
      _statusMessage = 'Mengecek update saldo wallet...';
    });

    try {
      await createBillingRepository().loadSnapshot();
      if (!mounted) return;
      setState(() {
        _checkingStatus = false;
        _statusMessage = 'Status billing sudah dicek. Jika webhook sudah masuk, saldo akan terlihat di dashboard.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingStatus = false;
        _statusMessage = 'Belum bisa mengecek status otomatis. Dashboard akan tetap direfresh saat dibuka.';
      });
    }
  }

  void _goToBilling() {
    if (!mounted) return;
    context.go(AppRoutes.billing);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 44),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: CostikStudioTheme.navy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.description,
                  style: const TextStyle(
                    color: CostikStudioTheme.slate,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: CostikStudioTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        if (_checkingStatus) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ] else ...[
                          Icon(
                            widget.isSuccess
                                ? Icons.sync_rounded
                                : Icons.info_outline_rounded,
                            color: CostikStudioTheme.primary,
                            size: 18,
                          ),
                        ],
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusMessage!,
                            style: const TextStyle(
                              color: CostikStudioTheme.navy,
                              fontWeight: FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Otomatis kembali ke Billing dalam beberapa detik.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: CostikStudioTheme.slate),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _goToBilling,
                  icon: const Icon(Icons.dashboard_rounded, size: 18),
                  label: const Text('Kembali ke Billing Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

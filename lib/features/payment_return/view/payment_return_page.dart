import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentReturnPage extends StatelessWidget {
  const PaymentReturnPage.success({super.key})
    : isSuccess = true,
      title = 'Pembayaran Diproses',
      description = 'Terima kasih. Jika pembayaran sudah berhasil, saldo wallet akan diperbarui otomatis setelah webhook Sumopod diterima.',
      icon = Icons.check_circle_rounded,
      color = Colors.green;

  const PaymentReturnPage.cancelled({super.key})
    : isSuccess = false,
      title = 'Pembayaran Dibatalkan',
      description = 'Pembayaran belum diselesaikan. Kamu bisa kembali ke Billing untuk membuat top up baru atau membatalkan transaksi pending.',
      icon = Icons.cancel_rounded,
      color = Colors.orange;

  final bool isSuccess;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

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
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 44),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: CostikStudioTheme.navy,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: CostikStudioTheme.slate,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.billing),
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

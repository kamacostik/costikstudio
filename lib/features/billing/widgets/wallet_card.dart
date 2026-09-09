import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({super.key, required this.balance, required this.onTopUp});

  final int balance;
  final VoidCallback onTopUp;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.account_balance_wallet_rounded, size: 34),
            const SizedBox(height: 18),
            const Text(
              'Wallet balance',
              style: TextStyle(
                color: CostikStudioTheme.slate,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatRupiah(balance),
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTopUp,
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Top up dummy Rp100.000'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

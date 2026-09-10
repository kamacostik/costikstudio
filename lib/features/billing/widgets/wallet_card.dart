import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.balance,
    required this.onTopUp,
    this.paymentOrders = const [],
  });

  final int balance;
  final ValueChanged<int> onTopUp;
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
                            const Text(
                              'Menunggu webhook',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
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
    if (amount != null) {
      onTopUp(amount);
    }
  }
}

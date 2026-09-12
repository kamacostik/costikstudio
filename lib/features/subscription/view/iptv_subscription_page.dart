import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_format.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/billing/billing_dependencies.dart';
import 'package:costikstudio/features/billing/cubit/billing_cubit.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class IptvSubscriptionPage extends StatefulWidget {
  const IptvSubscriptionPage({super.key, this.onBack, this.isEmbedded = false});

  final VoidCallback? onBack;
  final bool isEmbedded;

  @override
  State<IptvSubscriptionPage> createState() => _IptvSubscriptionPageState();
}

class _IptvSubscriptionPageState extends State<IptvSubscriptionPage> {
  final _formKey = GlobalKey<FormState>();
  final _deviceCountController = TextEditingController(text: '10');

  int _deviceCount = 10;
  int _billingCycleMonths = 1; // 1, 3, 6, 12 bulan
  bool _autoRenew = false;
  int? _pricePerDevice;

  ProductItem get _product => dummyProducts.firstWhere(
    (p) => p.id == 'costik-iptv',
    orElse: () => dummyProducts.first,
  );

  @override
  void initState() {
    super.initState();
    _deviceCountController.addListener(_onDeviceCountChanged);
  }

  void _onDeviceCountChanged() {
    final parsed = int.tryParse(_deviceCountController.text.trim()) ?? 0;
    if (parsed != _deviceCount) {
      setState(() {
        _deviceCount = parsed;
      });
    }
  }

  @override
  void dispose() {
    _deviceCountController.dispose();
    super.dispose();
  }

  int get _effectivePricePerDevice => _pricePerDevice ?? 0;

  int get _totalPrice =>
      _deviceCount * _effectivePricePerDevice * _billingCycleMonths;

  void _syncPriceFromSnapshot(BillingSnapshot? snapshot) {
    if (snapshot == null) return;
    final products = snapshot.products.where((p) => p.id == 'costik-iptv');
    final price = products.isEmpty ? null : products.first.pricePerDevice;
    if (price != null && price != _pricePerDevice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _pricePerDevice == price) return;
        setState(() => _pricePerDevice = price);
      });
    }
  }

  Future<void> _goToTopUpBalance() async {
    if (widget.isEmbedded) {
      Navigator.of(context).maybePop();
      return;
    }
    context.go(AppRoutes.billing);
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_effectivePricePerDevice <= 0) {
      await _showTopUpNeededDialog(
        message: 'Harga produk belum berhasil dimuat. Coba refresh halaman.',
      );
      return;
    }

    final billingCubit = context.read<BillingCubit>();
    final balance = billingCubit.state.snapshot?.wallet.balance ?? 0;
    if (balance < _totalPrice) {
      final shortfall = _totalPrice - balance;
      await _showTopUpNeededDialog(
        message: 'Saldo kurang ${formatRupiah(shortfall)}',
      );
      return;
    }

    await billingCubit.checkoutIptvSubscription(
      deviceCount: _deviceCount,
      billingCycleMonths: _billingCycleMonths,
      autoRenew: _autoRenew,
    );

    if (!mounted) return;

    if (billingCubit.state.status == BillingStatus.failure) {
      await _showTopUpNeededDialog(
        message:
            billingCubit.state.errorMessage ?? 'Langganan IPTV gagal diproses.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Langganan Berhasil Didaftarkan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terima kasih! Pesanan langganan Costik IPTV Anda telah dicatat:',
              style: TextStyle(color: CostikStudioTheme.slate),
            ),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Produk', value: 'Costik IPTV'),
            _SummaryRow(label: 'Jumlah Device', value: '$_deviceCount Device'),
            _SummaryRow(label: 'Durasi', value: '$_billingCycleMonths Bulan'),
            _SummaryRow(
              label: 'Total Tagihan',
              value: formatRupiah(_totalPrice),
              isBold: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.billing);
            },
            child: const Text('Ke Dashboard Billing'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTopUpNeededDialog({required String message}) async {
    final balance =
        context.read<BillingCubit>().state.snapshot?.wallet.balance ?? 0;
    final shortfall = (_totalPrice - balance).clamp(0, _totalPrice);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.orange,
              size: 28,
            ),
            SizedBox(width: 10),
            Text('Saldo Belum Cukup'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo wallet Anda belum cukup untuk melanjutkan langganan ini.',
              style: TextStyle(color: CostikStudioTheme.slate),
            ),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Saldo Saat Ini', value: formatRupiah(balance)),
            _SummaryRow(
              label: 'Total Langganan',
              value: formatRupiah(_totalPrice),
            ),
            _SummaryRow(
              label: 'Perlu Top Up',
              value: formatRupiah(shortfall),
              isBold: true,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Nanti Dulu'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _goToTopUpBalance();
            },
            icon: const Icon(Icons.add_card_rounded),
            label: const Text('Top Up Balance'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(_product.accentHex);

    final content = BlocProvider(
      create: (_) =>
          BillingCubit(repository: createBillingRepository())..load(),
      child: BlocBuilder<BillingCubit, BillingState>(
        builder: (context, billingState) {
          _syncPriceFromSnapshot(billingState.snapshot);
          final pricePerDevice = _effectivePricePerDevice;
          final isPriceLoading =
              billingState.status == BillingStatus.loading &&
              pricePerDevice <= 0;

          return Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb / Back
                TextButton.icon(
                  onPressed:
                      widget.onBack ??
                      () => context.go('${AppRoutes.products}/costik-iptv'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Kembali ke Katalog Produk'),
                  style: TextButton.styleFrom(
                    foregroundColor: CostikStudioTheme.slate,
                  ),
                ),
                const SizedBox(height: 12),

                // Title Section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.tv_rounded, color: accent, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Formulir Berlangganan Costik IPTV',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: CostikStudioTheme.navy,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Hitung kebutuhan lisensi device IPTV untuk hotel atau bisnis Anda dan lakukan aktivasi.',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: CostikStudioTheme.slate),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Main Layout (Form & Summary Card)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;

                    final formSection = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Device Calculation
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.devices_other_rounded,
                                      color: CostikStudioTheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Kalkulasi Kebutuhan Device',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Harga lisensi Costik IPTV adalah ${formatRupiah(pricePerDevice)} / device / bulan.',
                                  style: const TextStyle(
                                    color: CostikStudioTheme.slate,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Input Device
                                TextFormField(
                                  controller: _deviceCountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Jumlah Device (Kamar / Layar)',
                                    hintText: 'Contoh: 25',
                                    helperText:
                                        'Minimal 1 device (${formatRupiah(pricePerDevice)}/device/bulan)',
                                    prefixIcon: const Icon(Icons.tv_rounded),
                                    suffixText: 'Device',
                                  ),
                                  validator: (val) {
                                    final num = int.tryParse(val?.trim() ?? '');
                                    if (num == null || num < 1) {
                                      return 'Masukkan jumlah minimal 1 device';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Quick device selection buttons
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [10, 25, 50, 100, 200].map((
                                    preset,
                                  ) {
                                    final isSelected = _deviceCount == preset;
                                    return ChoiceChip(
                                      label: Text('$preset Device'),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        if (selected) {
                                          _deviceCountController.text = preset
                                              .toString();
                                        }
                                      },
                                    );
                                  }).toList(),
                                ),

                                const SizedBox(height: 26),
                                const Divider(),
                                const SizedBox(height: 18),

                                // Billing duration
                                Text(
                                  'Durasi Berlangganan',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children:
                                      [
                                        {'label': '1 Bulan', 'months': 1},
                                        {'label': '3 Bulan', 'months': 3},
                                        {'label': '6 Bulan', 'months': 6},
                                        {
                                          'label': '1 Tahun (12 Bln)',
                                          'months': 12,
                                        },
                                      ].map((item) {
                                        final months = item['months'] as int;
                                        final label = item['label'] as String;
                                        final isSelected =
                                            _billingCycleMonths == months;
                                        return ChoiceChip(
                                          label: Text(label),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() {
                                                _billingCycleMonths = months;
                                              });
                                            }
                                          },
                                        );
                                      }).toList(),
                                ),
                                const SizedBox(height: 26),
                                const Divider(),
                                const SizedBox(height: 18),

                                // Auto renew
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Auto-Renew per Bulan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    'Perpanjangan otomatis tiap bulan dari saldo wallet. Pastikan saldo mencukupi agar langganan tidak kedaluwarsa.',
                                    style: TextStyle(
                                      color: CostikStudioTheme.slate,
                                      fontSize: 12,
                                    ),
                                  ),
                                  secondary: const Icon(
                                    Icons.autorenew_rounded,
                                    color: CostikStudioTheme.primary,
                                  ),
                                  value: _autoRenew,
                                  onChanged: (value) {
                                    setState(() {
                                      _autoRenew = value;
                                    });
                                  },
                                ),
                                if (_autoRenew)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.info_outline_rounded,
                                          color: Colors.orange,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Saldo wallet harus mencukupi (${formatRupiah(_deviceCount * pricePerDevice)}/bulan) saat auto-renew berjalan, kalau tidak langganan bisa expire.',
                                            style: const TextStyle(
                                              color: CostikStudioTheme.slate,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );

                    final summarySection = Card(
                      color: CostikStudioTheme.navy,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ringkasan Pesanan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _OrderSummaryRow(
                              label: 'Produk',
                              value: 'Costik IPTV',
                            ),
                            _OrderSummaryRow(
                              label: 'Tarif per Device',
                              value: '${formatRupiah(pricePerDevice)} / bln',
                            ),
                            _OrderSummaryRow(
                              label: 'Jumlah Device',
                              value: '$_deviceCount unit',
                            ),
                            _OrderSummaryRow(
                              label: 'Durasi Berlangganan',
                              value: '$_billingCycleMonths Bulan',
                            ),
                            _OrderSummaryRow(
                              label: 'Auto-Renew',
                              value: _autoRenew ? 'Aktif' : 'Mati',
                            ),
                            const Divider(color: Colors.white24, height: 28),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Total Estimasi',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    formatRupiah(_totalPrice),
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: CostikStudioTheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: isPriceLoading || pricePerDevice <= 0
                                    ? null
                                    : _submitOrder,
                                icon: const Icon(Icons.check_circle_rounded),
                                label: const Text(
                                  'Konfirmasi & Lanjut Pembayaran',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Aktivasi instan & dukungan setup server cloud',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: formSection),
                          const SizedBox(width: 24),
                          SizedBox(width: 360, child: summarySection),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        formSection,
                        const SizedBox(height: 24),
                        summarySection,
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return SingleChildScrollView(child: ResponsiveSection(child: content));
  }
}

class _OrderSummaryRow extends StatelessWidget {
  const _OrderSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
          Text(label, style: const TextStyle(color: CostikStudioTheme.slate)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: isBold
                  ? CostikStudioTheme.primary
                  : CostikStudioTheme.navy,
            ),
          ),
        ],
      ),
    );
  }
}

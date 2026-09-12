import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/signage/cubit/signage_admin_cubit.dart';
import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignageDevicesSection extends StatefulWidget {
  const SignageDevicesSection({super.key});

  @override
  State<SignageDevicesSection> createState() => _SignageDevicesSectionState();
}

class _SignageDevicesSectionState extends State<SignageDevicesSection> {
  final _deviceNameController = TextEditingController(text: 'Android TV Lobby');

  @override
  void dispose() {
    _deviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignageAdminCubit, SignageAdminState>(
      builder: (context, state) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tv_rounded),
                    const SizedBox(width: 10),
                    Text(
                      'Devices',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: CostikStudioTheme.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: state.isSaving
                          ? null
                          : () => _showPairingDialog(context),
                      icon: const Icon(Icons.add_link_rounded),
                      label: const Text('Tambah Device'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => context.read<SignageAdminCubit>().load(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.devicePairing != null) ...[
                  _PairingCodeCard(pairing: state.devicePairing!),
                  const SizedBox(height: 12),
                ],
                if (state.devices.isEmpty)
                  const Text(
                    'Belum ada device terdaftar. Device dari Android TV/client akan tampil di sini setelah tersambung ke tenant.',
                    style: TextStyle(color: CostikStudioTheme.slate),
                  )
                else
                  Column(
                    children: [
                      for (final device in state.devices)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            device.isActive
                                ? Icons.check_circle_rounded
                                : Icons.pause_circle_outline_rounded,
                            color: device.isActive
                                ? Colors.green
                                : Colors.orange,
                          ),
                          title: Text(device.name),
                          subtitle: Text(
                            'Video: ${device.isVideo ? 'on' : 'off'} • Promo: ${device.isPromo ? 'on' : 'off'} • ${device.tableColumn} kolom',
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPairingDialog(BuildContext context) async {
    _deviceNameController.text = 'Android TV Lobby';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah Device Signage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buat kode pairing, lalu masukkan kode ini di APK Android TV.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _deviceNameController,
              decoration: const InputDecoration(
                labelText: 'Nama device',
                hintText: 'Contoh: Android TV Lobby',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Buat Kode'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<SignageAdminCubit>().createDevicePairing(
      deviceName: _deviceNameController.text.trim(),
    );
  }
}

class _PairingCodeCard extends StatelessWidget {
  const _PairingCodeCard({required this.pairing});

  final SignageDevicePairing pairing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CostikStudioTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CostikStudioTheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kode Pairing Android TV',
            style: TextStyle(
              color: CostikStudioTheme.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            pairing.pairingCode,
            style: const TextStyle(
              color: CostikStudioTheme.primary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masukkan kode ini di aplikasi Android TV. Berlaku sampai ${pairing.expiresAt.toLocal()}.',
            style: const TextStyle(color: CostikStudioTheme.slate),
          ),
        ],
      ),
    );
  }
}

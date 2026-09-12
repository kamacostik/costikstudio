import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/signage/cubit/signage_admin_cubit.dart';
import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:costikstudio/features/signage/view/widgets/signage_table_widgets.dart';
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
                SignageDataTable(
                  emptyIcon: Icons.tv_rounded,
                  emptyMessage: 'Belum ada device terdaftar. Device Android TV akan tampil setelah pairing.',
                  columns: [
                    signageDataColumn('Device'),
                    signageDataColumn('Layout'),
                    signageDataColumn('Konten'),
                    signageDataColumn('Status'),
                  ],
                  rows: [
                    for (final device in state.devices)
                      DataRow(
                        cells: [
                          DataCell(
                            SignageReferenceCell(
                              icon: Icons.tv_rounded,
                              iconColor: device.isActive
                                  ? Colors.green
                                  : Colors.orange,
                              title: device.name,
                              reference: device.id,
                            ),
                          ),
                          DataCell(Text('${device.tableColumn} kolom')),
                          DataCell(
                            Text(
                              'Video: ${device.isVideo ? 'On' : 'Off'} • Promo: ${device.isPromo ? 'On' : 'Off'}',
                            ),
                          ),
                          DataCell(
                            SignageStatusBadge(
                              label: device.isActive ? 'Aktif' : 'Nonaktif',
                              color: device.isActive
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
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
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        title: const _DeviceDialogHeader(),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _deviceNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama device',
                  hintText: 'Contoh: Android TV Lobby',
                  helperText:
                      'Nama ini akan tampil di daftar device Web Admin.',
                  prefixIcon: Icon(Icons.tv_rounded),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.qr_code_2_rounded),
            label: const Text('Buat Kode'),
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

class _DeviceDialogHeader extends StatelessWidget {
  const _DeviceDialogHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: CostikStudioTheme.primary.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: CostikStudioTheme.primary,
            child: Icon(Icons.add_link_rounded),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah Device Signage'),
                SizedBox(height: 4),
                Text(
                  'Buat kode pairing untuk menghubungkan APK Android TV.',
                  style: TextStyle(
                    color: CostikStudioTheme.slate,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _DeviceQuotaBadge(quota: state.deviceQuota),
                    FilledButton.icon(
                      onPressed:
                          state.isSaving || !state.deviceQuota.canAddDevice
                          ? null
                          : () => _showPairingDialog(context),
                      icon: const Icon(Icons.add_link_rounded),
                      label: const Text('Tambah Device'),
                    ),
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
                    signageDataColumn('Mode'),
                    signageDataColumn('Slide Event'),
                    signageDataColumn('Konten'),
                    signageDataColumn('Status'),
                    signageDataColumn('Pairing'),
                    signageDataColumn('Aksi'),
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
                            SignageStatusBadge(
                              label: device.appMode.label,
                              color:
                                  device.appMode == SignageAppMode.videoPlayer
                                  ? Colors.purple
                                  : CostikStudioTheme.navy,
                            ),
                          ),
                          DataCell(
                            Text('${device.eventSlideDurationSeconds} detik'),
                          ),
                          DataCell(
                            Text(
                              'Video: ${device.isVideo ? 'On' : 'Off'} • Promo: ${device.isPromo ? 'On' : 'Off'}',
                            ),
                          ),
                          DataCell(_DeviceStatusBadge(device: device)),
                          DataCell(_DevicePairingAction(device: device)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _DeviceSettingsAction(
                                  device: device,
                                  mediaItems: state.mediaItems,
                                ),
                                _DeviceDeleteAction(device: device),
                              ],
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
          width: (MediaQuery.sizeOf(context).width - 48)
              .clamp(280, 520)
              .toDouble(),
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
    if (!context.read<SignageAdminCubit>().state.deviceQuota.canAddDevice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kuota device penuh. Upgrade subscription Signage untuk menambah device.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await context.read<SignageAdminCubit>().createDevicePairing(
      deviceName: _deviceNameController.text.trim(),
    );
  }
}

class _DeviceStatusBadge extends StatelessWidget {
  const _DeviceStatusBadge({required this.device});

  final SignageDevice device;

  @override
  Widget build(BuildContext context) {
    if (device.isConnected) {
      return const SignageStatusBadge(label: 'Connected', color: Colors.green);
    }
    if (device.isWaitingPairing) {
      return const SignageStatusBadge(
        label: 'Menunggu Pairing',
        color: Colors.orange,
      );
    }
    if (device.isPairingExpired) {
      return const SignageStatusBadge(label: 'Kode Expired', color: Colors.red);
    }
    return const SignageStatusBadge(
      label: 'Belum Pairing',
      color: Colors.blueGrey,
    );
  }
}

class _DevicePairingAction extends StatelessWidget {
  const _DevicePairingAction({required this.device});

  final SignageDevice device;

  @override
  Widget build(BuildContext context) {
    if (device.isConnected) {
      return Text(
        device.lastSeenAt == null
            ? 'Sudah input kode'
            : 'Last seen ${_formatDeviceTime(device.lastSeenAt!)}',
        style: const TextStyle(color: CostikStudioTheme.slate),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (device.pairingCode != null && device.pairingCode!.isNotEmpty)
          SelectableText(
            device.pairingCode!,
            style: const TextStyle(
              color: CostikStudioTheme.primary,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          )
        else
          const Text('-', style: TextStyle(color: CostikStudioTheme.slate)),
        const SizedBox(width: 10),
        TextButton.icon(
          onPressed: () => context
              .read<SignageAdminCubit>()
              .regenerateDevicePairing(device.id),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: Text(device.isPairingExpired ? 'Generate Lagi' : 'Buat Ulang'),
        ),
      ],
    );
  }
}

String _formatDeviceTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class _DeviceQuotaBadge extends StatelessWidget {
  const _DeviceQuotaBadge({required this.quota});

  final SignageDeviceQuota quota;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: quota.canAddDevice
            ? CostikStudioTheme.primary.withValues(alpha: 0.10)
            : Colors.red.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Kuota ${quota.usedDevices}/${quota.deviceLimit}',
        style: TextStyle(
          color: quota.canAddDevice
              ? CostikStudioTheme.primary
              : Colors.red.shade700,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _DeviceSettingsAction extends StatelessWidget {
  const _DeviceSettingsAction({required this.device, required this.mediaItems});

  final SignageDevice device;
  final List<SignageMediaItem> mediaItems;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Setting device',
      icon: const Icon(Icons.tune_rounded),
      onPressed: () => _showSettingsDialog(context),
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) async {
    var slideDuration = device.eventSlideDurationSeconds.clamp(3, 60);
    var appMode = device.appMode;
    var eventBackgroundUrl = device.eventBackgroundUrl;
    final backgroundItems = mediaItems
        .where(
          (item) =>
              item.publicUrl != null &&
              item.publicUrl!.trim().isNotEmpty &&
              item.mediaType == 'image',
        )
        .toList();

    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: CostikStudioTheme.primary.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: CostikStudioTheme.primary,
                  child: Icon(Icons.tune_rounded),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Setting Device'),
                      const SizedBox(height: 4),
                      Text(
                        device.name,
                        style: const TextStyle(
                          color: CostikStudioTheme.slate,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: (MediaQuery.sizeOf(context).width - 48)
                .clamp(320, 460)
                .toDouble(),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mode Aplikasi',
                    style: TextStyle(fontWeight: FontWeight.w700, color: CostikStudioTheme.navy),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih tampilan utama pada layar TV.',
                    style: TextStyle(fontSize: 13, color: CostikStudioTheme.slate),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SignageAppMode>(
                    initialValue: appMode,
                    decoration: inputDecoration.copyWith(
                      prefixIcon: const Icon(Icons.apps_rounded),
                    ),
                    items: [
                      for (final mode in SignageAppMode.values)
                        DropdownMenuItem(value: mode, child: Text(mode.label)),
                    ],
                    onChanged: (mode) {
                      if (mode != null) setState(() => appMode = mode);
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Background (Tanpa Event)',
                    style: TextStyle(fontWeight: FontWeight.w700, color: CostikStudioTheme.navy),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gambar yang tampil jika tidak ada event hari ini.',
                    style: TextStyle(fontSize: 13, color: CostikStudioTheme.slate),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    initialValue: eventBackgroundUrl,
                    isExpanded: true,
                    decoration: inputDecoration.copyWith(
                      prefixIcon: const Icon(Icons.wallpaper_rounded),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Tidak pakai background'),
                      ),
                      for (final item in backgroundItems)
                        DropdownMenuItem<String?>(
                          value: item.publicUrl,
                          child: Text(item.fileName),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => eventBackgroundUrl = value),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Durasi Slide Event',
                    style: TextStyle(fontWeight: FontWeight.w700, color: CostikStudioTheme.navy),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Lama tiap gambar event tampil (berlaku jika event > 4).',
                    style: TextStyle(fontSize: 13, color: CostikStudioTheme.slate),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: slideDuration.toDouble(),
                          min: 3,
                          max: 60,
                          divisions: 57,
                          label: '$slideDuration detik',
                          onChanged: (value) =>
                              setState(() => slideDuration = value.round()),
                        ),
                      ),
                      Container(
                        width: 50,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${slideDuration}s',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: CostikStudioTheme.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
              icon: const Icon(Icons.save_rounded),
              label: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !context.mounted) return;
    final cubit = context.read<SignageAdminCubit>();
    if (appMode != device.appMode) {
      await cubit.updateDeviceAppMode(device.id, appMode: appMode);
    }
    if (eventBackgroundUrl != device.eventBackgroundUrl) {
      await cubit.updateDeviceEventBackground(
        device.id,
        eventBackgroundUrl: eventBackgroundUrl,
      );
    }
    if (slideDuration != device.eventSlideDurationSeconds) {
      await cubit.updateDeviceSlideDuration(
        device.id,
        durationSeconds: slideDuration,
      );
    }
  }
}

class _DeviceDeleteAction extends StatelessWidget {
  const _DeviceDeleteAction({required this.device});

  final SignageDevice device;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Hapus device',
      icon: const Icon(Icons.delete_outline_rounded),
      color: Colors.red.shade700,
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            titlePadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    child: Icon(Icons.warning_amber_rounded),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hapus Device?',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          device.name,
                          style: const TextStyle(
                            color: CostikStudioTheme.slate,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            content: const Text(
              'Device ini akan dihapus permanen dari tenant. Slot kuota Anda akan kembali tersedia dan dapat digunakan untuk device lain.',
              style: TextStyle(color: CostikStudioTheme.navy, fontSize: 14),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Ya, Hapus'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        await context.read<SignageAdminCubit>().deleteDevice(device.id);
      },
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

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/signage/cubit/signage_admin_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignageDevicesSection extends StatelessWidget {
  const SignageDevicesSection({super.key});

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
                    TextButton.icon(
                      onPressed: () => context.read<SignageAdminCubit>().load(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
}

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/signage/cubit/signage_admin_cubit.dart';
import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignageHotelProfileSection extends StatefulWidget {
  const SignageHotelProfileSection({super.key});

  @override
  State<SignageHotelProfileSection> createState() =>
      _SignageHotelProfileSectionState();
}

class _SignageHotelProfileSectionState
    extends State<SignageHotelProfileSection> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _logoController = TextEditingController();
  String? _loadedProfileId;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  void _syncControllers(SignageHotelProfile profile) {
    if (_loadedProfileId == profile.id) return;
    _loadedProfileId = profile.id;
    _nameController.text = profile.name;
    _addressController.text = profile.address;
    _descriptionController.text = profile.description;
    _logoController.text = profile.logoUrl;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignageAdminCubit, SignageAdminState>(
      builder: (context, state) {
        final profile = state.hotelProfile ?? const SignageHotelProfile();
        _syncControllers(profile);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business_rounded),
                    const SizedBox(width: 10),
                    Text(
                      'Hotel Profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: CostikStudioTheme.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama hotel'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _logoController,
                  decoration: const InputDecoration(
                    labelText: 'Logo URL / path',
                    helperText:
                        'Upload media akan dipindahkan pada batch berikutnya.',
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: state.isSaving
                        ? null
                        : () {
                            context.read<SignageAdminCubit>().saveHotelProfile(
                              SignageHotelProfile(
                                id: profile.id,
                                name: _nameController.text.trim(),
                                address: _addressController.text.trim(),
                                description: _descriptionController.text.trim(),
                                logoUrl: _logoController.text.trim(),
                              ),
                            );
                          },
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text('Simpan Hotel Profile'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

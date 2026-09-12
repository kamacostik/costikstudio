import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/signage/cubit/signage_admin_cubit.dart';
import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:file_picker/file_picker.dart';
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

  Future<void> _pickAndUploadLogo() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (!mounted || file == null) return;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      _showLogoError('File logo tidak bisa dibaca. Coba pilih file lain.');
      return;
    }
    if (bytes.length > 2 * 1024 * 1024) {
      _showLogoError('Ukuran logo maksimal 2 MB.');
      return;
    }

    final dimensions = await _decodeImageSize(bytes);
    if (!mounted) return;
    if (dimensions == null) {
      _showLogoError('Format gambar tidak valid. Gunakan PNG, JPG, atau WebP.');
      return;
    }
    final ratio = dimensions.width / dimensions.height;
    if (ratio < 1.6) {
      _showLogoError(
        'Logo harus horizontal. Rasio minimal 1.6:1, contoh 1200x400 atau 900x300.',
      );
      return;
    }

    final url = await context.read<SignageAdminCubit>().uploadHotelLogo(
      bytes: bytes,
      fileName: file.name,
      contentType: _contentTypeFor(file.name),
    );
    if (!mounted || url == null || url.isEmpty) return;
    setState(() => _logoController.text = url);
  }

  Future<({int width, int height})?> _decodeImageSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = (width: image.width, height: image.height);
      image.dispose();
      codec.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  void _showLogoError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
      );
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
                _LogoUploadField(
                  controller: _logoController,
                  isSaving: state.isSaving,
                  onUpload: _pickAndUploadLogo,
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

class _LogoUploadField extends StatelessWidget {
  const _LogoUploadField({
    required this.controller,
    required this.isSaving,
    required this.onUpload,
  });

  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final logoUrl = controller.text.trim();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CostikStudioTheme.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 190,
                    height: 78,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: CostikStudioTheme.primary.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: logoUrl.isEmpty
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.image_outlined,
                                color: CostikStudioTheme.slate,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Preview logo',
                                style: TextStyle(
                                  color: CostikStudioTheme.slate,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Image.network(
                            logoUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.red,
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Logo Hotel Horizontal',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: CostikStudioTheme.navy,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Upload logo PNG/JPG/WebP horizontal untuk tampil di Event Schedule dan Video Player. Rasio minimal 1.6:1, contoh 1200x400 atau 900x300. Maksimal 2 MB.',
                          style: TextStyle(
                            color: CostikStudioTheme.slate,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton.icon(
                              onPressed: isSaving ? null : onUpload,
                              icon: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.upload_file_rounded),
                              label: const Text('Upload Logo'),
                            ),
                            if (logoUrl.isNotEmpty)
                              TextButton.icon(
                                onPressed: isSaving ? null : controller.clear,
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Hapus URL'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Logo URL / path',
                  helperText: 'URL otomatis terisi setelah upload. Bisa juga ditempel manual jika logo sudah ada di CDN/storage.',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

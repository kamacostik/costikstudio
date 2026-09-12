import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/signage/cubit/signage_admin_cubit.dart';
import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignageMediaSection extends StatefulWidget {
  const SignageMediaSection({super.key});

  @override
  State<SignageMediaSection> createState() => _SignageMediaSectionState();
}

class _SignageMediaSectionState extends State<SignageMediaSection> {
  final _nameController = TextEditingController();
  final _pathController = TextEditingController();
  String _mediaType = 'image';

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignageAdminCubit, SignageAdminState>(
      builder: (context, state) {
        return _SectionCard(
          icon: Icons.perm_media_rounded,
          title: 'Media',
          subtitle: 'Daftarkan URL/path gambar atau video yang akan dipakai playlist.',
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama media',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 360,
                    child: TextField(
                      controller: _pathController,
                      decoration: const InputDecoration(
                        labelText: 'URL / storage path',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<String>(
                      initialValue: _mediaType,
                      decoration: const InputDecoration(labelText: 'Tipe'),
                      items: const [
                        DropdownMenuItem(value: 'image', child: Text('Image')),
                        DropdownMenuItem(value: 'video', child: Text('Video')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) =>
                          setState(() => _mediaType = value ?? 'image'),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: state.isSaving
                        ? null
                        : () {
                            final name = _nameController.text.trim();
                            final path = _pathController.text.trim();
                            if (name.isEmpty || path.isEmpty) return;
                            context.read<SignageAdminCubit>().saveMedia(
                              SignageMediaItem(
                                fileName: name,
                                storagePath: path,
                                publicUrl: path.startsWith('http')
                                    ? path
                                    : null,
                                mediaType: _mediaType,
                              ),
                            );
                            _nameController.clear();
                            _pathController.clear();
                          },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Simpan Media'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SimpleList(
                emptyText: 'Belum ada media.',
                children: [
                  for (final item in state.mediaItems)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        item.mediaType == 'video'
                            ? Icons.movie_rounded
                            : Icons.image_rounded,
                      ),
                      title: Text(item.fileName),
                      subtitle: Text(item.publicUrl ?? item.storagePath),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class SignagePlaylistSection extends StatefulWidget {
  const SignagePlaylistSection({super.key});

  @override
  State<SignagePlaylistSection> createState() => _SignagePlaylistSectionState();
}

class _SignagePlaylistSectionState extends State<SignagePlaylistSection> {
  final _nameController = TextEditingController();
  String? _mediaId;
  bool _enabled = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignageAdminCubit, SignageAdminState>(
      builder: (context, state) {
        final selectedMediaStillExists = state.mediaItems.any(
          (item) => item.id == _mediaId,
        );
        if (!selectedMediaStillExists) _mediaId = null;
        return _SectionCard(
          icon: Icons.playlist_play_rounded,
          title: 'Playlist',
          subtitle: 'Susun media yang akan ditampilkan oleh Android TV.',
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama playlist',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      initialValue: _mediaId,
                      decoration: const InputDecoration(labelText: 'Media'),
                      items: [
                        for (final item in state.mediaItems)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(item.fileName),
                          ),
                      ],
                      onChanged: (value) => setState(() => _mediaId = value),
                    ),
                  ),
                  FilterChip(
                    selected: _enabled,
                    label: const Text('Aktif'),
                    onSelected: (value) => setState(() => _enabled = value),
                  ),
                  FilledButton.icon(
                    onPressed: state.isSaving
                        ? null
                        : () {
                            final name = _nameController.text.trim();
                            if (name.isEmpty) return;
                            SignageMediaItem? media;
                            for (final item in state.mediaItems) {
                              if (item.id == _mediaId) {
                                media = item;
                                break;
                              }
                            }
                            context.read<SignageAdminCubit>().savePlaylist(
                              SignagePlaylistItem(
                                name: name,
                                mediaId: _mediaId,
                                path: media?.publicUrl ?? media?.storagePath,
                                isEnabled: _enabled,
                              ),
                            );
                            _nameController.clear();
                          },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Simpan Playlist'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SimpleList(
                emptyText: 'Belum ada playlist.',
                children: [
                  for (final item in state.playlists)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        item.isEnabled
                            ? Icons.play_circle_fill_rounded
                            : Icons.pause_circle_outline_rounded,
                      ),
                      title: Text(item.name),
                      subtitle: Text(item.path ?? 'Belum pilih media'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class SignageEventListSection extends StatefulWidget {
  const SignageEventListSection({super.key});

  @override
  State<SignageEventListSection> createState() =>
      _SignageEventListSectionState();
}

class _SignageEventListSectionState extends State<SignageEventListSection> {
  final _eventController = TextEditingController();
  final _roomController = TextEditingController();
  final _floorController = TextEditingController();
  String _direction = 'right';

  @override
  void dispose() {
    _eventController.dispose();
    _roomController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignageAdminCubit, SignageAdminState>(
      builder: (context, state) {
        return _SectionCard(
          icon: Icons.event_note_rounded,
          title: 'Event List',
          subtitle: 'Kelola agenda atau informasi meeting room untuk ditampilkan di layar.',
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 240,
                    child: TextField(
                      controller: _eventController,
                      decoration: const InputDecoration(
                        labelText: 'Nama event',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _roomController,
                      decoration: const InputDecoration(
                        labelText: 'Meeting room',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _floorController,
                      decoration: const InputDecoration(labelText: 'Floor'),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    child: DropdownButtonFormField<String>(
                      initialValue: _direction,
                      decoration: const InputDecoration(labelText: 'Direction'),
                      items: const [
                        DropdownMenuItem(value: 'right', child: Text('Right')),
                        DropdownMenuItem(value: 'left', child: Text('Left')),
                        DropdownMenuItem(value: 'up', child: Text('Up')),
                        DropdownMenuItem(value: 'down', child: Text('Down')),
                      ],
                      onChanged: (value) =>
                          setState(() => _direction = value ?? 'right'),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: state.isSaving
                        ? null
                        : () {
                            final eventName = _eventController.text.trim();
                            final room = _roomController.text.trim();
                            if (eventName.isEmpty || room.isEmpty) return;
                            context.read<SignageAdminCubit>().saveEvent(
                              SignageEventItem(
                                eventName: eventName,
                                meetingRoom: room,
                                floor: _floorController.text.trim(),
                                direction: _direction,
                              ),
                            );
                            _eventController.clear();
                            _roomController.clear();
                            _floorController.clear();
                          },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Simpan Event'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SimpleList(
                emptyText: 'Belum ada event.',
                children: [
                  for (final item in state.events)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_available_rounded),
                      title: Text(item.eventName),
                      subtitle: Text(
                        '${item.meetingRoom} • Floor ${item.floor} • ${item.direction}',
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class SignageProfileMenuSection extends StatelessWidget {
  const SignageProfileMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SectionCard(
      icon: Icons.manage_accounts_rounded,
      title: 'Profile & Menu',
      subtitle: 'Pengaturan akses menu admin Signage.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MenuStatusTile(label: 'Dashboard', enabled: true),
          _MenuStatusTile(label: 'Profil Hotel', enabled: true),
          _MenuStatusTile(label: 'Devices', enabled: true),
          _MenuStatusTile(label: 'Media', enabled: true),
          _MenuStatusTile(label: 'Playlist', enabled: true),
          _MenuStatusTile(label: 'Event List', enabled: true),
          SizedBox(height: 12),
          Text(
            'Hak akses multi-user akan ditambahkan setelah modul utama stabil.',
            style: TextStyle(color: CostikStudioTheme.slate),
          ),
        ],
      ),
    );
  }
}

class _MenuStatusTile extends StatelessWidget {
  const _MenuStatusTile({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: enabled,
      onChanged: null,
      title: Text(label),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: CostikStudioTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: CostikStudioTheme.navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(color: CostikStudioTheme.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({required this.emptyText, required this.children});

  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          emptyText,
          style: const TextStyle(color: CostikStudioTheme.slate),
        ),
      );
    }
    return Column(children: children);
  }
}

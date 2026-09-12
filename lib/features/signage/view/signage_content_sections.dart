import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/signage/cubit/signage_admin_cubit.dart';
import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:costikstudio/features/signage/view/widgets/signage_table_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _StyledDialogHeader extends StatelessWidget {
  const _StyledDialogHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: CostikStudioTheme.primary.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            foregroundColor: CostikStudioTheme.primary,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
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

class SignageMediaSection extends StatelessWidget {
  const SignageMediaSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignageAdminCubit, SignageAdminState>(
      builder: (context, state) {
        return _SectionCard(
          icon: Icons.perm_media_rounded,
          title: 'Media',
          subtitle: 'Daftarkan URL/path gambar atau video yang akan dipakai playlist.',
          action: FilledButton.icon(
            onPressed: state.isSaving ? null : () => _showMediaDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Media'),
          ),
          child: SignageDataTable(
            emptyIcon: Icons.perm_media_rounded,
            emptyMessage: 'Belum ada media.',
            columns: [
              signageDataColumn('Media'),
              signageDataColumn('Tipe'),
              signageDataColumn('Path / URL'),
            ],
            rows: [
              for (final item in state.mediaItems)
                DataRow(
                  cells: [
                    DataCell(
                      SignageReferenceCell(
                        icon: item.mediaType == 'video'
                            ? Icons.movie_rounded
                            : Icons.image_rounded,
                        iconColor: CostikStudioTheme.primary,
                        title: item.fileName,
                        reference: item.id ?? '-',
                      ),
                    ),
                    DataCell(Text(item.mediaType.toUpperCase())),
                    DataCell(Text(item.publicUrl ?? item.storagePath)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMediaDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final pathController = TextEditingController();
    var mediaType = 'image';
    final item = await showDialog<SignageMediaItem>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          title: const _StyledDialogHeader(
            icon: Icons.perm_media_rounded,
            title: 'Tambah Media',
            subtitle:
                'Tambahkan URL gambar atau video untuk bahan playlist signage.',
          ),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama media',
                    prefixIcon: Icon(Icons.badge_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pathController,
                  decoration: const InputDecoration(
                    labelText: 'URL / storage path',
                    helperText: 'Sementara bisa pakai URL langsung; upload storage menyusul.',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mediaType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe media',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'image', child: Text('Image')),
                    DropdownMenuItem(value: 'video', child: Text('Video')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => mediaType = value ?? 'image'),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded),
              onPressed: () {
                final name = nameController.text.trim();
                final path = pathController.text.trim();
                if (name.isEmpty || path.isEmpty) return;
                Navigator.of(dialogContext).pop(
                  SignageMediaItem(
                    fileName: name,
                    storagePath: path,
                    publicUrl: path.startsWith('http') ? path : null,
                    mediaType: mediaType,
                  ),
                );
              },
              label: const Text('Simpan Media'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    pathController.dispose();
    if (item != null && context.mounted) {
      await context.read<SignageAdminCubit>().saveMedia(item);
    }
  }
}

class SignagePlaylistSection extends StatelessWidget {
  const SignagePlaylistSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignageAdminCubit, SignageAdminState>(
      builder: (context, state) {
        return _SectionCard(
          icon: Icons.playlist_play_rounded,
          title: 'Playlist',
          subtitle: 'Susun media yang akan ditampilkan oleh Android TV.',
          action: FilledButton.icon(
            onPressed: state.isSaving
                ? null
                : () => _showPlaylistDialog(context, state),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Playlist'),
          ),
          child: SignageDataTable(
            emptyIcon: Icons.playlist_play_rounded,
            emptyMessage: 'Belum ada playlist.',
            columns: [
              signageDataColumn('Playlist'),
              signageDataColumn('Media / Path'),
              signageDataColumn('Status'),
            ],
            rows: [
              for (final item in state.playlists)
                DataRow(
                  cells: [
                    DataCell(
                      SignageReferenceCell(
                        icon: item.isEnabled
                            ? Icons.play_circle_fill_rounded
                            : Icons.pause_circle_outline_rounded,
                        iconColor: item.isEnabled
                            ? Colors.green
                            : Colors.orange,
                        title: item.name,
                        reference: item.id ?? '-',
                      ),
                    ),
                    DataCell(Text(item.path ?? 'Belum pilih media')),
                    DataCell(
                      SignageStatusBadge(
                        label: item.isEnabled ? 'Aktif' : 'Nonaktif',
                        color: item.isEnabled ? Colors.green : Colors.orange,
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

  Future<void> _showPlaylistDialog(
    BuildContext context,
    SignageAdminState state,
  ) async {
    final nameController = TextEditingController();
    String? mediaId;
    var enabled = true;
    final item = await showDialog<SignagePlaylistItem>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          title: const _StyledDialogHeader(
            icon: Icons.playlist_play_rounded,
            title: 'Tambah Playlist',
            subtitle:
                'Pilih media dan aktifkan playlist untuk layar Android TV.',
          ),
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama playlist',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mediaId,
                  decoration: const InputDecoration(
                    labelText: 'Media',
                    prefixIcon: Icon(Icons.perm_media_rounded),
                  ),
                  items: [
                    for (final media in state.mediaItems)
                      DropdownMenuItem(
                        value: media.id,
                        child: Text(media.fileName),
                      ),
                  ],
                  onChanged: (value) => setState(() => mediaId = value),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: enabled,
                  title: const Text('Aktif'),
                  onChanged: (value) => setState(() => enabled = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save_rounded),
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                SignageMediaItem? media;
                for (final item in state.mediaItems) {
                  if (item.id == mediaId) {
                    media = item;
                    break;
                  }
                }
                Navigator.of(dialogContext).pop(
                  SignagePlaylistItem(
                    name: name,
                    mediaId: mediaId,
                    path: media?.publicUrl ?? media?.storagePath,
                    isEnabled: enabled,
                  ),
                );
              },
              label: const Text('Simpan Playlist'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (item != null && context.mounted) {
      await context.read<SignageAdminCubit>().savePlaylist(item);
    }
  }
}

class SignageEventListSection extends StatelessWidget {
  const SignageEventListSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignageAdminCubit, SignageAdminState>(
      builder: (context, state) {
        return _SectionCard(
          icon: Icons.event_note_rounded,
          title: 'Daily Event',
          subtitle: 'Kelola event harian berdasarkan tanggal, jam mulai, dan jam selesai.',
          action: FilledButton.icon(
            onPressed: state.isSaving ? null : () => _showEventDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Event'),
          ),
          child: _DailyEventTabs(events: state.events),
        );
      },
    );
  }
}

class _DailyEventTabs extends StatefulWidget {
  const _DailyEventTabs({required this.events});

  final List<SignageEventItem> events;

  @override
  State<_DailyEventTabs> createState() => _DailyEventTabsState();
}

class _DailyEventTabsState extends State<_DailyEventTabs> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.events]
      ..sort((a, b) => _eventStart(a).compareTo(_eventStart(b)));
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final todayEvents = sorted
        .where((event) => _isSameDay(_eventStart(event), today))
        .toList();
    final tomorrowEvents = sorted
        .where((event) => _isSameDay(_eventStart(event), tomorrow))
        .toList();
    final upcomingEvents = sorted.where((event) {
      return _dateOnly(_eventStart(event)).isAfter(_dateOnly(tomorrow));
    }).toList();
    final pastEvents = sorted
        .where((event) {
          return _dateOnly(_eventStart(event)).isBefore(_dateOnly(today));
        })
        .toList()
        .reversed
        .toList();

    final groups = [
      _DailyEventGroup(
        label: 'Hari Ini',
        icon: Icons.today_rounded,
        events: todayEvents,
        emptyText: 'Belum ada event hari ini.',
      ),
      _DailyEventGroup(
        label: 'Besok',
        icon: Icons.next_plan_rounded,
        events: tomorrowEvents,
        emptyText: 'Belum ada event besok.',
      ),
      _DailyEventGroup(
        label: 'Akan Datang',
        icon: Icons.upcoming_rounded,
        events: upcomingEvents,
        emptyText: 'Belum ada event yang akan datang.',
      ),
      _DailyEventGroup(
        label: 'Selesai',
        icon: Icons.history_rounded,
        events: pastEvents,
        emptyText: 'Belum ada event selesai.',
      ),
    ];
    final activeGroup = groups[_activeIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SignageTableTabBar(
          children: [
            for (var i = 0; i < groups.length; i++)
              SignageTableTab(
                label: groups[i].label,
                icon: groups[i].icon,
                count: groups[i].events.length,
                isSelected: _activeIndex == i,
                onTap: () => setState(() => _activeIndex = i),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _DailyEventTable(group: activeGroup),
      ],
    );
  }
}

class _DailyEventGroup {
  const _DailyEventGroup({
    required this.label,
    required this.icon,
    required this.events,
    required this.emptyText,
  });

  final String label;
  final IconData icon;
  final List<SignageEventItem> events;
  final String emptyText;
}

class _DailyEventTable extends StatelessWidget {
  const _DailyEventTable({required this.group});

  final _DailyEventGroup group;

  @override
  Widget build(BuildContext context) {
    return SignageDataTable(
      emptyIcon: group.icon,
      emptyMessage: group.emptyText,
      columns: [
        signageDataColumn('Event'),
        signageDataColumn('Tanggal'),
        signageDataColumn('Jam'),
        signageDataColumn('Room / Floor'),
        signageDataColumn('Direction'),
      ],
      rows: [
        for (final item in group.events)
          DataRow(
            cells: [
              DataCell(
                SignageReferenceCell(
                  icon: Icons.event_available_rounded,
                  iconColor: CostikStudioTheme.primary,
                  title: item.eventName,
                  reference: item.id ?? '-',
                ),
              ),
              DataCell(Text(_formatDate(_eventStart(item)))),
              DataCell(
                Text(
                  '${_formatTime(_eventStart(item))} - ${_formatTime(_eventEnd(item))}',
                ),
              ),
              DataCell(Text('${item.meetingRoom} • Floor ${item.floor}')),
              DataCell(Text(item.direction)),
            ],
          ),
      ],
    );
  }
}

DateTime _eventStart(SignageEventItem item) => item.startDate ?? DateTime.now();

DateTime _eventEnd(SignageEventItem item) => item.endDate ?? _eventStart(item);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

Future<void> _showEventDialog(BuildContext context) async {
  final eventController = TextEditingController();
  final roomController = TextEditingController();
  final floorController = TextEditingController();
  var direction = 'right';
  var eventDate = DateTime.now();
  var startTime = const TimeOfDay(hour: 9, minute: 0);
  var endTime = const TimeOfDay(hour: 10, minute: 0);

  final item = await showDialog<SignageEventItem>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        Future<void> pickDate() async {
          final picked = await showDatePicker(
            context: context,
            initialDate: eventDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now().add(const Duration(days: 730)),
          );
          if (picked != null) setState(() => eventDate = picked);
        }

        Future<void> pickStartTime() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: startTime,
          );
          if (picked != null) setState(() => startTime = picked);
        }

        Future<void> pickEndTime() async {
          final picked = await showTimePicker(
            context: context,
            initialTime: endTime,
          );
          if (picked != null) setState(() => endTime = picked);
        }

        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          title: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: CostikStudioTheme.primary.withValues(alpha: 0.10),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: CostikStudioTheme.primary,
                  child: Icon(Icons.event_note_rounded),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tambah Daily Event'),
                      SizedBox(height: 4),
                      Text(
                        'Event akan tampil di client sesuai tanggal hari berjalan.',
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
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: eventController,
                    decoration: const InputDecoration(
                      labelText: 'Nama event',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: roomController,
                          decoration: const InputDecoration(
                            labelText: 'Meeting room',
                            prefixIcon: Icon(Icons.meeting_room_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: floorController,
                          decoration: const InputDecoration(
                            labelText: 'Floor',
                            prefixIcon: Icon(Icons.layers_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Jadwal Event',
                    style: TextStyle(
                      color: CostikStudioTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _PickerChip(
                        icon: Icons.calendar_today_rounded,
                        label: 'Tanggal',
                        value: _formatDate(eventDate),
                        onTap: pickDate,
                      ),
                      _PickerChip(
                        icon: Icons.play_arrow_rounded,
                        label: 'Mulai',
                        value: startTime.format(context),
                        onTap: pickStartTime,
                      ),
                      _PickerChip(
                        icon: Icons.stop_rounded,
                        label: 'Selesai',
                        value: endTime.format(context),
                        onTap: pickEndTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: direction,
                    decoration: const InputDecoration(
                      labelText: 'Direction',
                      prefixIcon: Icon(Icons.assistant_direction_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'right', child: Text('Right')),
                      DropdownMenuItem(value: 'left', child: Text('Left')),
                      DropdownMenuItem(value: 'up', child: Text('Up')),
                      DropdownMenuItem(value: 'down', child: Text('Down')),
                    ],
                    onChanged: (value) =>
                        setState(() => direction = value ?? 'right'),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () {
                final eventName = eventController.text.trim();
                final room = roomController.text.trim();
                if (eventName.isEmpty || room.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Nama event dan meeting room wajib diisi.'),
                    ),
                  );
                  return;
                }
                final startDateTime = DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                  startTime.hour,
                  startTime.minute,
                );
                final endDateTime = DateTime(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                  endTime.hour,
                  endTime.minute,
                );
                if (!endDateTime.isAfter(startDateTime)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        'Jam selesai harus lebih besar dari jam mulai.',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(
                  SignageEventItem(
                    eventName: eventName,
                    meetingRoom: room,
                    floor: floorController.text.trim(),
                    direction: direction,
                    startDate: startDateTime,
                    endDate: endDateTime,
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Simpan Event'),
            ),
          ],
        );
      },
    ),
  );
  eventController.dispose();
  roomController.dispose();
  floorController.dispose();
  if (item != null && context.mounted) {
    await context.read<SignageAdminCubit>().saveEvent(item);
  }
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 185,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CostikStudioTheme.primary.withValues(alpha: 0.18),
          ),
          color: CostikStudioTheme.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: CostikStudioTheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: CostikStudioTheme.slate,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: CostikStudioTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime? value) {
  if (value == null) return '-';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _formatTime(DateTime? value) {
  if (value == null) return '--:--';
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class SignageProfileMenuSection extends StatelessWidget {
  const SignageProfileMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    const menus = [
      'Dashboard',
      'Profil Hotel',
      'Devices',
      'Media',
      'Playlist',
      'Daily Event',
    ];

    return _SectionCard(
      icon: Icons.manage_accounts_rounded,
      title: 'Profile & Menu',
      subtitle: 'Pengaturan akses menu admin Signage.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignageDataTable(
            emptyIcon: Icons.manage_accounts_rounded,
            emptyMessage: 'Belum ada menu aktif.',
            columns: [
              signageDataColumn('Menu'),
              signageDataColumn('Akses'),
              signageDataColumn('Status'),
            ],
            rows: [
              for (final menu in menus)
                DataRow(
                  cells: [
                    DataCell(
                      SignageReferenceCell(
                        icon: Icons.menu_open_rounded,
                        iconColor: CostikStudioTheme.primary,
                        title: menu,
                        reference: 'Web Admin Signage',
                      ),
                    ),
                    const DataCell(Text('Owner')),
                    const DataCell(
                      SignageStatusBadge(label: 'Aktif', color: Colors.green),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Hak akses multi-user akan ditambahkan setelah modul utama stabil.',
            style: TextStyle(color: CostikStudioTheme.slate),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? action;

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
                if (action != null) ...[const SizedBox(width: 12), action!],
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

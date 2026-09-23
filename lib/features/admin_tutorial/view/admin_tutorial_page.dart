import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminTutorialPage extends StatefulWidget {
  const AdminTutorialPage({super.key});

  @override
  State<AdminTutorialPage> createState() => _AdminTutorialPageState();
}

class _AdminTutorialPageState extends State<AdminTutorialPage> {
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('tutorial_videos')
          .select()
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _videos = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat data tutorial: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteVideo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Video'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus video tutorial ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('tutorial_videos')
          .delete()
          .eq('id', id);
      await _fetchVideos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video berhasil dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menghapus video: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleActive(String id, bool currentStatus) async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('tutorial_videos')
          .update({'is_active': !currentStatus})
          .eq('id', id);
      await _fetchVideos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengupdate status: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFormDialog([Map<String, dynamic>? video]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TutorialFormDialog(
        video: video,
        onSaved: () {
          _fetchVideos();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ResponsiveSection(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 56),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ADMIN · TUTORIAL VIDEOS',
              style: TextStyle(
                color: CostikStudioTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kelola Video Tutorial',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: CostikStudioTheme.navy,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _showFormDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Video'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Atur video panduan yang akan tampil di Dashboard Member.',
              style: TextStyle(color: CostikStudioTheme.slate, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              )
            else if (_videos.isEmpty)
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(48),
                  alignment: Alignment.center,
                  child: const Text('Belum ada data video tutorial.'),
                ),
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _videos.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    final isActive = video['is_active'] as bool? ?? true;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      leading: Container(
                        width: 80,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(6),
                          image: DecorationImage(
                            image: NetworkImage(
                              'https://img.youtube.com/vi/${video['video_id']}/mqdefault.jpg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      ),
                      title: Text(
                        video['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        video['description'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.5),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: isActive ? 'Sembunyikan' : 'Tampilkan',
                            child: Switch(
                              value: isActive,
                              onChanged: (_) => _toggleActive(
                                video['id'] as String,
                                isActive,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.blue,
                            ),
                            onPressed: () => _showFormDialog(video),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () =>
                                _deleteVideo(video['id'] as String),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TutorialFormDialog extends StatefulWidget {
  const _TutorialFormDialog({this.video, required this.onSaved});

  final Map<String, dynamic>? video;
  final VoidCallback onSaved;

  @override
  State<_TutorialFormDialog> createState() => _TutorialFormDialogState();
}

class _TutorialFormDialogState extends State<_TutorialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _videoIdController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _sortOrderController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.video?['title'] as String? ?? '',
    );
    _videoIdController = TextEditingController(
      text: widget.video?['video_id'] as String? ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.video?['description'] as String? ?? '',
    );
    _sortOrderController = TextEditingController(
      text: (widget.video?['sort_order'] ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _videoIdController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final data = {
      'title': _titleController.text.trim(),
      'video_id': _videoIdController.text.trim(),
      'description': _descriptionController.text.trim(),
      'sort_order': int.tryParse(_sortOrderController.text) ?? 0,
    };

    try {
      if (widget.video == null) {
        // Insert
        data['is_active'] = true;
        await Supabase.instance.client.from('tutorial_videos').insert(data);
      } else {
        // Update
        await Supabase.instance.client
            .from('tutorial_videos')
            .update(data)
            .eq('id', widget.video!['id']);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video tutorial berhasil disimpan.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.video == null ? 'Tambah Video' : 'Edit Video'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Video',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'Judul tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _videoIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID YouTube (contoh: dQw4w9WgXcQ)',
                    border: OutlineInputBorder(),
                    helperText: 'Hanya ambil ID unik setelah ?v=',
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? 'ID Video tidak boleh kosong'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sortOrderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Urutan Tampil (Sort Order)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v == null || int.tryParse(v) == null
                      ? 'Harus berupa angka'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi / Panduan Singkat',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

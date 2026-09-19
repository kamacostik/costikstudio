import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class TutorialVideo {
  const TutorialVideo({
    required this.id,
    required this.title,
    required this.videoId,
    required this.description,
  });

  factory TutorialVideo.fromJson(Map<String, dynamic> json) {
    return TutorialVideo(
      id: json['id'] as String,
      title: json['title'] as String,
      videoId: json['video_id'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  final String id;
  final String title;
  final String videoId;
  final String description;
}

class DashboardTutorialPage extends StatefulWidget {
  const DashboardTutorialPage({super.key});

  @override
  State<DashboardTutorialPage> createState() => _DashboardTutorialPageState();
}

class _DashboardTutorialPageState extends State<DashboardTutorialPage> {
  List<TutorialVideo> _videos = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final response = await Supabase.instance.client
          .from('tutorial_videos')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      final videos = (response as List)
          .map((data) => TutorialVideo.fromJson(data as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _videos = videos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat tutorial: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_videos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(
          child: Text(
            'Belum ada video tutorial yang tersedia.',
            style: TextStyle(color: CostikStudioTheme.slate),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final crossAxisCount = isCompact
            ? 1
            : (constraints.maxWidth < 1000 ? 2 : 3);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
            childAspectRatio: 0.85,
          ),
          itemCount: _videos.length,
          itemBuilder: (context, index) {
            return _TutorialVideoCard(video: _videos[index]);
          },
        );
      },
    );
  }
}

class _TutorialVideoCard extends StatefulWidget {
  const _TutorialVideoCard({required this.video});

  final TutorialVideo video;

  @override
  State<_TutorialVideoCard> createState() => _TutorialVideoCardState();
}

class _TutorialVideoCardState extends State<_TutorialVideoCard> {
  late final YoutubePlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _isPlaying
                ? YoutubePlayer(controller: _controller)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://img.youtube.com/vi/${widget.video.videoId}/maxresdefault.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.black87,
                          child: const Center(
                            child: Icon(
                              Icons.video_library_rounded,
                              color: Colors.white54,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.2)),
                      Center(
                        child: IconButton(
                          icon: const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 64,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() => _isPlaying = true);
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: CostikStudioTheme.navy,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      widget.video.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CostikStudioTheme.slate,
                        height: 1.5,
                      ),
                      overflow: TextOverflow.fade,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

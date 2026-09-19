import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class TutorialVideo {
  const TutorialVideo({
    required this.title,
    required this.videoId,
    required this.description,
  });

  final String title;
  final String videoId;
  final String description;
}

const _tutorialVideos = [
  TutorialVideo(
    title: 'Konfigurasi DCO (Device Owner)',
    videoId: 'dQw4w9WgXcQ', // Placeholder
    description: 'Panduan lengkap cara mengaktifkan dan mengonfigurasi Device Owner pada STB/TV via ADB Manager.',
  ),
  TutorialVideo(
    title: 'Instalasi Aplikasi via Jaringan',
    videoId: 'dQw4w9WgXcQ', // Placeholder
    description: 'Cara melakukan install dan update aplikasi IPTV secara massal melalui jaringan.',
  ),
  TutorialVideo(
    title: 'Penggunaan Web Admin IPTV',
    videoId: 'dQw4w9WgXcQ', // Placeholder
    description: 'Panduan navigasi Web Admin untuk mengatur channel, VOD, dan layanan tamu hotel.',
  ),
];

class DashboardTutorialPage extends StatelessWidget {
  const DashboardTutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          itemCount: _tutorialVideos.length,
          itemBuilder: (context, index) {
            final video = _tutorialVideos[index];
            return _TutorialVideoCard(video: video);
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

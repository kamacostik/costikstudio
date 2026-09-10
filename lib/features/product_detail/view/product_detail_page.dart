import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.product});

  final ProductItem? product;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _selectedImageIndex = 0;

  // Mock product screenshots/gallery
  final List<Map<String, String>> _iptvScreenshots = const [
    {
      'title': 'Dashboard Live TV & EPG',
      'url': 'https://picsum.photos/seed/iptv1/800/450',
      'caption': 'Tampilan antarmuka Live TV interaktif dengan informasi acara EPG realtime.',
    },
    {
      'title': 'Guest Welcome Screen',
      'url': 'https://picsum.photos/seed/iptv2/800/450',
      'caption': 'Layar sambutan personalisasi untuk tamu hotel dengan informasi resort & fasilitas.',
    },
    {
      'title': 'VOD & Hotel Services',
      'url': 'https://picsum.photos/seed/iptv3/800/450',
      'caption': 'Katalog Video on Demand & pemesanan layanan room service langsung dari TV.',
    },
  ];

  void _showDocumentationModal(BuildContext context, ProductItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: CostikStudioTheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Panduan Penggunaan ${item.name}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: CostikStudioTheme.navy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _DocSection(
                    stepNumber: '1',
                    title: 'Persyaratan Hardware & Jaringan',
                    content: 'Pastikan Smart TV atau Set Top Box (Android TV / Linux STB) terhubung ke dalam jaringan local LAN / Wi-Fi hotel yang sama dengan Server Costik IPTV.',
                  ),
                  _DocSection(
                    stepNumber: '2',
                    title: 'Instalasi Aplikasi Client',
                    content: 'Unduh dan buka file `.apk` Costik IPTV Client dari Download Center. Masukkan IP Server Host atau aktivasi dengan Licence Key yang terdaftar.',
                  ),
                  _DocSection(
                    stepNumber: '3',
                    title: 'Pengaturan Admin & Channel Playlist',
                    content: 'Akses Web Admin Costik Studio (`/admin`) untuk mengunggah M3U Playlist channel, mengatur urutan kategori channel, dan mendesain banner promosi.',
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CostikStudioTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: CostikStudioTheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.video_library_rounded,
                              color: CostikStudioTheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Tutorial Video YouTube',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: CostikStudioTheme.navy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Saksikan video walkthrough step-by-step setup Costik IPTV untuk perhotelan di channel YouTube resmi kami.',
                          style: TextStyle(
                            color: CostikStudioTheme.slate,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            // Link ke video YouTube tutorial
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Membuka video tutorial di YouTube...',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_circle_fill_rounded),
                          label: const Text('Tonton Tutorial di YouTube'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFFF0000,
                            ), // YouTube red
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Tutup Panduan'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.product;
    if (item == null) {
      return ResponsiveSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product not found',
              style: Theme.of(context).textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/products'),
              child: const Text('Back to products'),
            ),
          ],
        ),
      );
    }

    final accent = Color(item.accentHex);
    final isAuthenticated = context.select<AuthCubit, bool>(
      (cubit) => cubit.state.isAuthenticated,
    );

    return SingleChildScrollView(
      child: ResponsiveSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/products'),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Back to products'),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(34),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.status.name.toUpperCase(),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _showDocumentationModal(context, item),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text('Dokumentasi & Tutorial Video'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: CostikStudioTheme.slate, height: 1.6),
                  ),
                  const SizedBox(height: 28),

                  // Image Showcase Carousel / Preview
                  Text(
                    'Tampilan Aplikasi',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: CostikStudioTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 320,
                    decoration: BoxDecoration(
                      color: CostikStudioTheme.navy,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _iptvScreenshots[_selectedImageIndex]['url']!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: CostikStudioTheme.navy,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.tv_rounded,
                                            size: 64,
                                            color: CostikStudioTheme.cyan,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Costik IPTV Product Preview',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _iptvScreenshots[_selectedImageIndex]['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _iptvScreenshots[_selectedImageIndex]['caption']!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_iptvScreenshots.length, (index) {
                      final isSelected = index == _selectedImageIndex;
                      return InkWell(
                        onTap: () =>
                            setState(() => _selectedImageIndex = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? accent : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Screenshot ${index + 1}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : CostikStudioTheme.slate,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (isAuthenticated) ...[
                        if (item.hasAdmin)
                          FilledButton.icon(
                            onPressed: () => context.go('/support'),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Open web admin'),
                          ),
                        FilledButton.icon(
                          onPressed: () {
                            if (item.id == 'costik-iptv') {
                              context.go(AppRoutes.subscribeIptv);
                            } else {
                              context.go(AppRoutes.billing);
                            }
                          },
                          icon: const Icon(Icons.workspace_premium_rounded),
                          label: const Text('Berlangganan sekarang'),
                        ),
                        if (item.hasDownload)
                          OutlinedButton.icon(
                            onPressed: () => context.go(AppRoutes.apps),
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Download app'),
                          ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.login),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Login untuk berlangganan'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Key features',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            for (final feature in item.features)
              Card(
                child: ListTile(
                  leading: Icon(Icons.check_circle_rounded, color: accent),
                  title: Text(feature),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocSection extends StatelessWidget {
  const _DocSection({
    required this.stepNumber,
    required this.title,
    required this.content,
  });

  final String stepNumber;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: CostikStudioTheme.primary,
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CostikStudioTheme.navy,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    color: CostikStudioTheme.slate,
                    height: 1.4,
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

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

  List<_ProductPreview> _previewsFor(ProductItem item) {
    if (item.id == 'costik-iptv') {
      return const [
        _ProductPreview(
          title: 'Guest Room IPTV Home',
          caption: 'Layar utama untuk tamu hotel: live TV, informasi hotel, promo, dan akses layanan kamar.',
          icon: Icons.tv_rounded,
        ),
        _ProductPreview(
          title: 'Channel & EPG Management',
          caption: 'Admin dapat mengatur channel, kategori, playlist M3U, dan urutan konten dari web dashboard.',
          icon: Icons.playlist_play_rounded,
        ),
        _ProductPreview(
          title: 'Room Device Monitoring',
          caption: 'Pantau status device kamar, lisensi aktif, dan kebutuhan maintenance dari satu tempat.',
          icon: Icons.meeting_room_rounded,
        ),
      ];
    }

    return [
      _ProductPreview(
        title: '${item.name} Dashboard',
        caption: item.tagline,
        icon: Icons.dashboard_customize_rounded,
      ),
      const _ProductPreview(
        title: 'Operational Workflow',
        caption: 'Alur kerja dibuat sederhana agar tim operasional mudah mulai tanpa training panjang.',
        icon: Icons.route_rounded,
      ),
      const _ProductPreview(
        title: 'Reports & Visibility',
        caption: 'Ringkasan data penting untuk membantu owner dan supervisor mengambil keputusan cepat.',
        icon: Icons.insights_rounded,
      ),
    ];
  }

  List<_DocStep> _docStepsFor(ProductItem item) {
    if (item.id == 'costik-iptv') {
      return const [
        _DocStep(
          title: 'Pilih jumlah device dan durasi',
          content: 'Dari halaman berlangganan, tentukan jumlah TV/STB yang akan dipasang dan pilih siklus pembayaran.',
        ),
        _DocStep(
          title: 'Top up wallet sebelum checkout',
          content: 'Pastikan saldo wallet cukup. Jika saldo kurang, sistem akan mengarahkan user ke top up balance.',
        ),
        _DocStep(
          title: 'Aktivasi perangkat kamar',
          content: 'Setelah subscription aktif, pasang aplikasi client pada Android TV/STB dan hubungkan licence/device code.',
        ),
        _DocStep(
          title: 'Kelola channel dan konten hotel',
          content: 'Gunakan dashboard admin untuk playlist, kategori channel, banner promosi, informasi hotel, dan konten tamu.',
        ),
      ];
    }

    return [
      _DocStep(
        title: 'Login dan pilih produk',
        content:
            'Masuk ke Costik Studio, buka produk ${item.name}, lalu lanjutkan ke dashboard layanan.',
      ),
      const _DocStep(
        title: 'Konfigurasi data awal',
        content: 'Lengkapi data master, user operasional, dan pengaturan dasar sesuai kebutuhan bisnis.',
      ),
      const _DocStep(
        title: 'Pantau aktivitas rutin',
        content: 'Gunakan ringkasan dashboard, laporan, dan riwayat aktivitas untuk monitoring harian.',
      ),
    ];
  }

  List<_FaqItem> _faqFor(ProductItem item) {
    if (item.id == 'costik-iptv') {
      return const [
        _FaqItem(
          question: 'Apakah bisa dipakai untuk hotel kecil?',
          answer: 'Bisa. Paket dihitung per device sehingga bisa mulai dari jumlah kamar kecil dan ditambah saat kebutuhan bertambah.',
        ),
        _FaqItem(
          question: 'Apakah harus selalu online?',
          answer: 'Dashboard, billing, dan sinkronisasi membutuhkan internet. Untuk pemutaran konten tertentu, konfigurasi lokal dapat disiapkan bertahap.',
        ),
        _FaqItem(
          question: 'Bagaimana kalau tambah TV baru?',
          answer: 'User dapat memperpanjang atau menambah jumlah device melalui flow upgrade/renew yang akan disiapkan di Billing.',
        ),
      ];
    }

    return const [
      _FaqItem(
        question: 'Apakah produk ini sudah siap produksi?',
        answer: 'Saat ini masih tahap beta dan terus dirapikan sesuai kebutuhan awal pengguna.',
      ),
      _FaqItem(
        question: 'Apakah bisa request fitur tambahan?',
        answer: 'Bisa. Request fitur dapat diarahkan melalui halaman Support setelah login.',
      ),
    ];
  }

  void _showDocumentationModal(BuildContext context, ProductItem item) {
    final docSteps = _docStepsFor(item);
    final faqs = _faqFor(item);

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
                      Expanded(
                        child: Text(
                          'Panduan ${item.name}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: CostikStudioTheme.navy,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Dokumentasi singkat untuk membantu user memahami setup, aktivasi, dan alur penggunaan produk.',
                    style: TextStyle(
                      color: CostikStudioTheme.slate,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < docSteps.length; i++)
                    _DocSection(stepNumber: '${i + 1}', step: docSteps[i]),
                  const SizedBox(height: 18),
                  _TutorialVideoCard(productName: item.name),
                  const SizedBox(height: 22),
                  Text(
                    'FAQ',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: CostikStudioTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final faq in faqs) _FaqTile(item: faq),
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
    final previews = _previewsFor(item);
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 30,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _StatusPill(
                        label: item.status.name.toUpperCase(),
                        color: accent,
                      ),
                      _StatusPill(
                        label: item.isFree ? 'FREE APP' : 'SAAS PRODUCT',
                        color: item.isFree
                            ? Colors.green
                            : CostikStudioTheme.primary,
                      ),
                      _StatusPill(
                        label: item.category.name.toUpperCase(),
                        color: Colors.indigo,
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
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (isAuthenticated) ...[
                        FilledButton.icon(
                          onPressed: () {
                            if (item.id == 'costik-iptv') {
                              context.go(AppRoutes.subscribeIptv);
                            } else {
                              context.go(AppRoutes.billing);
                            }
                          },
                          icon: const Icon(Icons.workspace_premium_rounded),
                          label: Text(
                            item.isFree
                                ? 'Buka dari Apps'
                                : 'Berlangganan sekarang',
                          ),
                        ),
                        if (item.hasAdmin)
                          OutlinedButton.icon(
                            onPressed: () => context.go('/support'),
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Info web admin'),
                          ),
                      ] else ...[
                        FilledButton.icon(
                          onPressed: () => context.go(AppRoutes.login),
                          icon: const Icon(Icons.login_rounded),
                          label: const Text('Login untuk berlangganan'),
                        ),
                      ],
                      OutlinedButton.icon(
                        onPressed: () => _showDocumentationModal(context, item),
                        icon: const Icon(Icons.menu_book_rounded, size: 18),
                        label: const Text('Lihat Dokumentasi'),
                      ),
                      if (item.hasDownload)
                        OutlinedButton.icon(
                          onPressed: () => context.go(AppRoutes.apps),
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download app'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _PreviewShowcase(
              previews: previews,
              selectedIndex: _selectedImageIndex,
              accent: accent,
              onSelected: (index) =>
                  setState(() => _selectedImageIndex = index),
            ),
            const SizedBox(height: 28),
            _HowItWorksSection(product: item),
            const SizedBox(height: 28),
            Text(
              'Key features',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: item.features
                  .map(
                    (feature) => SizedBox(
                      width: 360,
                      child: _FeatureTile(feature: feature, color: accent),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewShowcase extends StatelessWidget {
  const _PreviewShowcase({
    required this.previews,
    required this.selectedIndex,
    required this.accent,
    required this.onSelected,
  });

  final List<_ProductPreview> previews;
  final int selectedIndex;
  final Color accent;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = previews[selectedIndex];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CostikStudioTheme.navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tampilan Aplikasi',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(selected.icon, size: 64, color: accent),
                const SizedBox(height: 18),
                Text(
                  selected.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selected.caption,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.55,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(previews.length, (index) {
              final isSelected = index == selectedIndex;
              return ChoiceChip(
                selected: isSelected,
                label: Text(previews[index].title),
                onSelected: (_) => onSelected(index),
                selectedColor: accent,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : CostikStudioTheme.navy,
                  fontWeight: FontWeight.w800,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({required this.product});

  final ProductItem product;

  @override
  Widget build(BuildContext context) {
    final steps = product.id == 'costik-iptv'
        ? const [
            _DocStep(
              title: 'Top up wallet',
              content: 'Isi saldo melalui Billing, bayar di Sumopod, lalu saldo masuk otomatis setelah webhook berhasil.',
            ),
            _DocStep(
              title: 'Checkout IPTV',
              content: 'Pilih jumlah device dan durasi langganan sesuai kebutuhan kamar atau area TV.',
            ),
            _DocStep(
              title: 'Aktivasi device',
              content: 'Hubungkan aplikasi client ke lisensi aktif dan mulai kelola channel/konten hotel.',
            ),
          ]
        : [
            const _DocStep(
              title: 'Login akun',
              content: 'Masuk ke Costik Studio untuk membuka dashboard produk dan data layanan.',
            ),
            _DocStep(
              title: 'Setup ${product.name}',
              content: 'Lengkapi konfigurasi awal dan data operasional utama.',
            ),
            const _DocStep(
              title: 'Pantau operasional',
              content: 'Gunakan dashboard dan laporan untuk melihat perkembangan harian.',
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cara mulai',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: List.generate(
            steps.length,
            (index) => SizedBox(
              width: 360,
              child: _StepCard(number: index + 1, step: steps[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.number, required this.step});

  final int number;
  final _DocStep step;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: CostikStudioTheme.primary,
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              step.title,
              style: const TextStyle(
                color: CostikStudioTheme.navy,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              step.content,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature, required this.color});

  final String feature;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.check_circle_rounded, color: color),
        title: Text(
          feature,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _TutorialVideoCard extends StatelessWidget {
  const _TutorialVideoCard({required this.productName});

  final String productName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF0000).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF0000).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.video_library_rounded, color: Color(0xFFFF0000)),
              SizedBox(width: 8),
              Text(
                'Tutorial Video',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: CostikStudioTheme.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Video walkthrough $productName akan diarahkan ke YouTube resmi Costik Studio ketika materi sudah dipublish.',
            style: const TextStyle(
              color: CostikStudioTheme.slate,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tutorial video sedang disiapkan.'),
                ),
              );
            },
            icon: const Icon(Icons.play_circle_fill_rounded),
            label: const Text('Tonton Tutorial'),
          ),
        ],
      ),
    );
  }
}

class _DocSection extends StatelessWidget {
  const _DocSection({required this.stepNumber, required this.step});

  final String stepNumber;
  final _DocStep step;

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
                  step.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: CostikStudioTheme.navy,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.content,
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});

  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          item.question,
          style: const TextStyle(
            color: CostikStudioTheme.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.answer,
              style: const TextStyle(
                color: CostikStudioTheme.slate,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPreview {
  const _ProductPreview({
    required this.title,
    required this.caption,
    required this.icon,
  });

  final String title;
  final String caption;
  final IconData icon;
}

class _DocStep {
  const _DocStep({required this.title, required this.content});

  final String title;
  final String content;
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

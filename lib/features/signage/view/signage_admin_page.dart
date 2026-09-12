import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:costikstudio/core/billing/billing_core.dart';
import 'package:costikstudio/core/billing/billing_repository.dart';
import 'package:costikstudio/features/billing/billing_dependencies.dart';
import 'package:costikstudio/features/billing/cubit/billing_cubit.dart';
import 'package:costikstudio/features/signage/cubit/signage_admin_cubit.dart';
import 'package:costikstudio/features/signage/cubit/signage_cubit.dart';
import 'package:costikstudio/features/signage/data/signage_admin_repository.dart';
import 'package:costikstudio/features/signage/data/supabase_signage_repository.dart';
import 'package:costikstudio/features/signage/view/signage_devices_section.dart';
import 'package:costikstudio/features/signage/view/signage_hotel_profile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignageAdminPage extends StatelessWidget {
  const SignageAdminPage({super.key, this.repository});

  final BillingRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              BillingCubit(repository: repository ?? createBillingRepository())
                ..load(),
        ),
        BlocProvider(
          create: (_) =>
              SignageCubit(repository: const SupabaseSignageRepository())
                ..loadTenant(),
        ),
        BlocProvider(
          create: (_) => SignageAdminCubit(
            repository: const SupabaseSignageAdminRepository(),
          ),
        ),
      ],
      child: const _SignageAdminView(),
    );
  }
}

class _SignageAdminView extends StatelessWidget {
  const _SignageAdminView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BillingCubit, BillingState>(
      listener: (context, state) {
        final error = state.errorMessage;
        if (error != null && error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text(error)),
          );
        }
      },
      builder: (context, billingState) {
        final snapshot = billingState.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final subscription = _activeSignageSubscription(snapshot);
        if (subscription == null) {
          return const _NoActiveSignageSubscription();
        }

        return BlocBuilder<SignageCubit, SignageState>(
          builder: (context, signageState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Costik Signage Admin',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: CostikStudioTheme.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kelola data signage langsung dari CostikStudio. Akses ini hanya aktif untuk subscription Costik Signage yang masih berlaku.',
                    style: TextStyle(color: CostikStudioTheme.slate),
                  ),
                  const SizedBox(height: 20),
                  _SubscriptionAccessCard(subscription: subscription),
                  const SizedBox(height: 16),
                  if (signageState.tenant == null)
                    _ProvisionTenantCard(isLoading: signageState.isLoading)
                  else
                    _TenantReadyCard(
                      tenantName: signageState.tenant!.tenantName,
                    ),
                  if (signageState.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      signageState.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  if (signageState.tenant != null) ...[
                    _SignageAdminModules(subscription: subscription),
                  ] else ...[
                    const _TenantRequiredModulesNotice(),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Subscription? _activeSignageSubscription(BillingSnapshot snapshot) {
    final now = DateTime.now();
    for (final subscription in snapshot.subscriptions) {
      if (subscription.productId == 'costik-signage' &&
          subscription.status == SubscriptionStatus.active &&
          subscription.expiresAt.isAfter(now)) {
        return subscription;
      }
    }
    return null;
  }
}

class _NoActiveSignageSubscription extends StatelessWidget {
  const _NoActiveSignageSubscription();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.lock_outline_rounded, size: 44, color: Colors.orange),
              SizedBox(height: 14),
              Text(
                'Subscription Costik Signage belum aktif',
                style: TextStyle(
                  color: CostikStudioTheme.navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Aktifkan langganan Digital Signage dari menu Produk untuk membuka Web Admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CostikStudioTheme.slate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionAccessCard extends StatelessWidget {
  const _SubscriptionAccessCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified_user_rounded, color: Colors.green),
        title: const Text('Subscription Signage aktif'),
        subtitle: Text(
          '${subscription.deviceCount} device • berlaku sampai ${subscription.expiresAt.toLocal()}',
        ),
      ),
    );
  }
}

class _ProvisionTenantCard extends StatelessWidget {
  const _ProvisionTenantCard({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Siapkan tenant Signage untuk akun ini agar data hotel, device, playlist, dan event terpisah per pemilik.',
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: isLoading
                  ? null
                  : () => context.read<SignageCubit>().provisionTenant(),
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_business_rounded),
              label: const Text('Siapkan Tenant'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantRequiredModulesNotice extends StatelessWidget {
  const _TenantRequiredModulesNotice();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.info_outline_rounded, color: CostikStudioTheme.primary),
            SizedBox(height: 12),
            Text(
              'Siapkan Tenant dulu untuk membuka menu Web Admin.',
              style: TextStyle(
                color: CostikStudioTheme.navy,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tenant akan menjadi workspace Signage akun ini, sehingga Profil Hotel, Devices, Media, Playlist, dan Event List tersimpan terpisah dari pengguna lain.',
              style: TextStyle(color: CostikStudioTheme.slate),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantReadyCard extends StatelessWidget {
  const _TenantReadyCard({required this.tenantName});

  final String tenantName;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.withValues(alpha: 0.06),
      child: ListTile(
        leading: const Icon(Icons.check_circle_rounded, color: Colors.green),
        title: Text('Tenant aktif: $tenantName'),
        subtitle: const Text(
          'Data Signage akan dibatasi oleh RLS sesuai tenant akun ini.',
        ),
      ),
    );
  }
}

enum _SignageAdminTab {
  dashboard,
  hotelProfile,
  devices,
  media,
  playlists,
  eventLists,
  profileMenu,
}

class _SignageAdminModules extends StatefulWidget {
  const _SignageAdminModules({required this.subscription});

  final Subscription subscription;

  @override
  State<_SignageAdminModules> createState() => _SignageAdminModulesState();
}

class _SignageAdminModulesState extends State<_SignageAdminModules> {
  _SignageAdminTab _selectedTab = _SignageAdminTab.dashboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SignageAdminCubit>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignageAdminCubit, SignageAdminState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(state.errorMessage!),
            ),
          );
        } else if (state.successMessage != null &&
            state.successMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.successMessage!)));
        }
      },
      builder: (context, state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                _SignageAdminSectionHeader(tab: _selectedTab),
                const SizedBox(height: 14),
                _buildContent(state),
              ],
            );

            if (!isWide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SignageAdminMobileMenu(
                    selectedTab: _selectedTab,
                    onChanged: (tab) => setState(() => _selectedTab = tab),
                  ),
                  const SizedBox(height: 16),
                  content,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 260,
                  child: _SignageAdminSidebar(
                    selectedTab: _selectedTab,
                    subscription: widget.subscription,
                    onChanged: (tab) => setState(() => _selectedTab = tab),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(child: content),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildContent(SignageAdminState state) {
    return switch (_selectedTab) {
      _SignageAdminTab.dashboard => _SignageAdminDashboard(
        subscription: widget.subscription,
        state: state,
        onOpenTab: (tab) => setState(() => _selectedTab = tab),
      ),
      _SignageAdminTab.hotelProfile => const SignageHotelProfileSection(),
      _SignageAdminTab.devices => const SignageDevicesSection(),
      _SignageAdminTab.media => const _ComingSoonModule(
        icon: Icons.perm_media_rounded,
        title: 'Media Library',
        description: 'Tempat upload dan kelola gambar/video signage. Modul ini berikutnya dipindahkan dari Admin Signage lama ke tabel sg_media.',
      ),
      _SignageAdminTab.playlists => const _ComingSoonModule(
        icon: Icons.playlist_play_rounded,
        title: 'Playlist',
        description: 'Susun urutan media, jadwal tayang, dan konten per device. Modul ini akan terhubung ke sg_playlists.',
      ),
      _SignageAdminTab.eventLists => const _ComingSoonModule(
        icon: Icons.event_note_rounded,
        title: 'Event List',
        description: 'Kelola agenda/event hotel untuk ditampilkan di layar signage. Modul ini akan terhubung ke sg_event_lists.',
      ),
      _SignageAdminTab.profileMenu => const _ComingSoonModule(
        icon: Icons.manage_accounts_rounded,
        title: 'Profile & Menu Access',
        description: 'Pengaturan profil tenant, hak akses menu, dan preferensi admin. Modul ini akan dipindahkan setelah modul operasional utama.',
      ),
    };
  }
}

class _SignageAdminSidebar extends StatelessWidget {
  const _SignageAdminSidebar({
    required this.selectedTab,
    required this.subscription,
    required this.onChanged,
  });

  final _SignageAdminTab selectedTab;
  final Subscription subscription;
  final ValueChanged<_SignageAdminTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Web Admin',
              style: TextStyle(
                color: CostikStudioTheme.navy,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${subscription.deviceCount} device aktif',
              style: const TextStyle(color: CostikStudioTheme.slate),
            ),
            const Divider(height: 28),
            for (final item in _signageAdminMenuItems)
              _SignageAdminMenuTile(
                item: item,
                selected: selectedTab == item.tab,
                onTap: () => onChanged(item.tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _SignageAdminMobileMenu extends StatelessWidget {
  const _SignageAdminMobileMenu({
    required this.selectedTab,
    required this.onChanged,
  });

  final _SignageAdminTab selectedTab;
  final ValueChanged<_SignageAdminTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final item in _signageAdminMenuItems)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: selectedTab == item.tab,
                avatar: Icon(item.icon, size: 18),
                label: Text(item.label),
                onSelected: (_) => onChanged(item.tab),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignageAdminMenuTile extends StatelessWidget {
  const _SignageAdminMenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _SignageAdminMenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? CostikStudioTheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: Icon(
            item.icon,
            color: selected
                ? CostikStudioTheme.primary
                : CostikStudioTheme.slate,
          ),
          title: Text(
            item.label,
            style: TextStyle(
              color: selected
                  ? CostikStudioTheme.primary
                  : CostikStudioTheme.navy,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          trailing: item.isReady
              ? null
              : const Tooltip(
                  message: 'Segera dipindahkan',
                  child: Icon(Icons.schedule_rounded, size: 18),
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SignageAdminSectionHeader extends StatelessWidget {
  const _SignageAdminSectionHeader({required this.tab});

  final _SignageAdminTab tab;

  @override
  Widget build(BuildContext context) {
    final item = _signageAdminMenuItems.firstWhere((entry) => entry.tab == tab);
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: CostikStudioTheme.primary.withValues(alpha: 0.10),
          foregroundColor: CostikStudioTheme.primary,
          child: Icon(item.icon),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: CostikStudioTheme.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                item.description,
                style: const TextStyle(color: CostikStudioTheme.slate),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignageAdminDashboard extends StatelessWidget {
  const _SignageAdminDashboard({
    required this.subscription,
    required this.state,
    required this.onOpenTab,
  });

  final Subscription subscription;
  final SignageAdminState state;
  final ValueChanged<_SignageAdminTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final hasHotelProfile = (state.hotelProfile?.name ?? '').isNotEmpty;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.tv_rounded,
                label: 'Kuota Device',
                value: '${subscription.deviceCount}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.devices_other_rounded,
                label: 'Device Terdaftar',
                value: '${state.devices.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.business_rounded,
                label: 'Profil Hotel',
                value: hasHotelProfile ? 'Ready' : 'Belum',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 1000 ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            for (final item in _signageAdminMenuItems.where(
              (item) => item.tab != _SignageAdminTab.dashboard,
            ))
              _ModuleShortcutCard(item: item, onTap: () => onOpenTab(item.tab)),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: CostikStudioTheme.primary),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: CostikStudioTheme.navy,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            Text(label, style: const TextStyle(color: CostikStudioTheme.slate)),
          ],
        ),
      ),
    );
  }
}

class _ModuleShortcutCard extends StatelessWidget {
  const _ModuleShortcutCard({required this.item, required this.onTap});

  final _SignageAdminMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.icon, color: CostikStudioTheme.primary),
                  const Spacer(),
                  Chip(
                    label: Text(item.isReady ? 'Aktif' : 'Next'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.label,
                style: const TextStyle(
                  color: CostikStudioTheme.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: CostikStudioTheme.slate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoonModule extends StatelessWidget {
  const _ComingSoonModule({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: CostikStudioTheme.primary, size: 34),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: CostikStudioTheme.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: CostikStudioTheme.slate),
            ),
            const SizedBox(height: 18),
            const Chip(label: Text('Belum aktif - tahap porting berikutnya')),
          ],
        ),
      ),
    );
  }
}

class _SignageAdminMenuItem {
  const _SignageAdminMenuItem({
    required this.tab,
    required this.label,
    required this.description,
    required this.icon,
    required this.isReady,
  });

  final _SignageAdminTab tab;
  final String label;
  final String description;
  final IconData icon;
  final bool isReady;
}

const _signageAdminMenuItems = [
  _SignageAdminMenuItem(
    tab: _SignageAdminTab.dashboard,
    label: 'Dashboard',
    description: 'Ringkasan tenant, subscription, dan status modul Signage.',
    icon: Icons.dashboard_rounded,
    isReady: true,
  ),
  _SignageAdminMenuItem(
    tab: _SignageAdminTab.hotelProfile,
    label: 'Profil Hotel',
    description: 'Identitas hotel yang tampil di layar Signage.',
    icon: Icons.business_rounded,
    isReady: true,
  ),
  _SignageAdminMenuItem(
    tab: _SignageAdminTab.devices,
    label: 'Devices',
    description: 'Daftar Android TV/player yang terhubung ke tenant ini.',
    icon: Icons.tv_rounded,
    isReady: true,
  ),
  _SignageAdminMenuItem(
    tab: _SignageAdminTab.media,
    label: 'Media',
    description: 'Upload dan kelola konten gambar/video.',
    icon: Icons.perm_media_rounded,
    isReady: false,
  ),
  _SignageAdminMenuItem(
    tab: _SignageAdminTab.playlists,
    label: 'Playlist',
    description: 'Susun konten yang akan tampil di layar.',
    icon: Icons.playlist_play_rounded,
    isReady: false,
  ),
  _SignageAdminMenuItem(
    tab: _SignageAdminTab.eventLists,
    label: 'Event List',
    description: 'Agenda/event hotel untuk tampilan signage.',
    icon: Icons.event_note_rounded,
    isReady: false,
  ),
  _SignageAdminMenuItem(
    tab: _SignageAdminTab.profileMenu,
    label: 'Profile & Menu',
    description: 'Pengaturan profil tenant dan akses menu.',
    icon: Icons.manage_accounts_rounded,
    isReady: false,
  ),
];

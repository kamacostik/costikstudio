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
              SignageCubit(repository: const SupabaseSignageRepository()),
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
                    const _SignageAdminModules(),
                  ] else ...[
                    const _SignageModulesPreview(),
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

class _SignageAdminModules extends StatefulWidget {
  const _SignageAdminModules();

  @override
  State<_SignageAdminModules> createState() => _SignageAdminModulesState();
}

class _SignageAdminModulesState extends State<_SignageAdminModules> {
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            const SignageHotelProfileSection(),
            const SizedBox(height: 16),
            const SignageDevicesSection(),
            const SizedBox(height: 22),
            const _SignageModulesPreview(),
          ],
        );
      },
    );
  }
}

class _SignageModulesPreview extends StatelessWidget {
  const _SignageModulesPreview();

  @override
  Widget build(BuildContext context) {
    final modules = const [
      ('Hotel Profile', Icons.business_rounded),
      ('Devices', Icons.tv_rounded),
      ('Media', Icons.perm_media_rounded),
      ('Playlists', Icons.playlist_play_rounded),
      ('Event Lists', Icons.event_note_rounded),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final module in modules)
          SizedBox(
            width: 220,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(module.$2, color: CostikStudioTheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      module.$1,
                      style: const TextStyle(
                        color: CostikStudioTheme.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Module akan dipindahkan dari repo Admin Signage lama.',
                      style: TextStyle(color: CostikStudioTheme.slate),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

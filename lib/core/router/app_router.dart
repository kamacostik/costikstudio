import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/account/view/account_page.dart';
import 'package:costikstudio/features/adb_manager/view/adb_manager_page.dart';
import 'package:costikstudio/features/admin_dashboard/view/admin_dashboard_page.dart';
import 'package:costikstudio/features/admin_product_gallery/view/admin_product_gallery_page.dart';
import 'package:costikstudio/features/apps/view/apps_page.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/auth/view/login_page.dart';
import 'package:costikstudio/features/billing/view/admin_billing_page.dart';
import 'package:costikstudio/features/billing/view/billing_dashboard_page.dart';
import 'package:costikstudio/features/home/view/home_page.dart';
import 'package:costikstudio/features/payment_return/view/payment_return_page.dart';
import 'package:costikstudio/features/product_detail/view/product_detail_page.dart';
import 'package:costikstudio/features/products/view/products_page.dart';
import 'package:costikstudio/features/signage/view/admin_signage_page.dart';
import 'package:costikstudio/features/signage/view/signage_admin_page.dart';
import 'package:costikstudio/features/subscription/view/iptv_subscription_page.dart';
import 'package:costikstudio/features/subscription/view/signage_subscription_page.dart';
import 'package:costikstudio/features/support/view/support_page.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter(
  AppExperience experience, {
  AuthCubit? authCubit,
  AuthState authState = const AuthState(),
}) {
  final isAdminApp = experience == AppExperience.admin;
  final isAdbApp = experience == AppExperience.adb;

  return GoRouter(
    initialLocation: _initialLocationFor(experience, authState),
    refreshListenable: authCubit == null
        ? null
        : _AuthRouterRefreshNotifier(authCubit.stream),
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            CostikStudioShell(experience: experience, child: child),
        routes: [
          if (!isAdminApp && !isAdbApp) ...[
            GoRoute(
              path: AppRoutes.home,
              name: AppRouteNames.home,
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: '/produk',
              redirect: (context, state) => AppRoutes.products,
            ),
            GoRoute(
              path: AppRoutes.products,
              name: AppRouteNames.products,
              builder: (context, state) => const ProductsPage(),
            ),
            GoRoute(
              path: AppRoutes.subscribeIptv,
              name: AppRouteNames.subscribeIptv,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAuthenticated) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const IptvSubscriptionPage(),
            ),
            GoRoute(
              path: AppRoutes.subscribeSignage,
              name: AppRouteNames.subscribeSignage,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAuthenticated) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const SignageSubscriptionPage(),
            ),
            GoRoute(
              path: '${AppRoutes.products}/:id',
              name: AppRouteNames.productDetail,
              builder: (context, state) {
                final product = findProductById(
                  state.pathParameters['id'] ?? '',
                );
                return ProductDetailPage(product: product);
              },
            ),
            GoRoute(
              path: AppRoutes.apps,
              name: AppRouteNames.apps,
              builder: (context, state) => const AppsPage(),
            ),
            GoRoute(
              path: AppRoutes.downloads,
              redirect: (context, state) => AppRoutes.apps,
            ),
            GoRoute(
              path: AppRoutes.login,
              name: AppRouteNames.login,
              builder: (context, state) => const LoginPage(),
            ),
            GoRoute(
              path: AppRoutes.account,
              name: AppRouteNames.account,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAuthenticated) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const AccountPage(),
            ),
            GoRoute(
              path: AppRoutes.billing,
              name: AppRouteNames.billing,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAuthenticated) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const BillingDashboardPage(),
            ),
            GoRoute(
              path: AppRoutes.paymentSuccess,
              name: AppRouteNames.paymentSuccess,
              builder: (context, state) => const PaymentReturnPage.success(),
            ),
            GoRoute(
              path: AppRoutes.paymentCancel,
              name: AppRouteNames.paymentCancel,
              builder: (context, state) => const PaymentReturnPage.cancelled(),
            ),
            GoRoute(
              path: AppRoutes.adminBilling,
              name: AppRouteNames.adminBilling,
              redirect: (context, state) => AppRoutes.billing,
            ),
            GoRoute(
              path: AppRoutes.adminDashboard,
              redirect: (context, state) => AppRoutes.billing,
            ),
            GoRoute(
              path: AppRoutes.adminSignage,
              redirect: (context, state) => AppRoutes.billing,
            ),
            GoRoute(
              path: AppRoutes.support,
              name: AppRouteNames.support,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAuthenticated) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const SupportPage(),
            ),
            GoRoute(
              path: AppRoutes.signageAdmin,
              name: AppRouteNames.signageAdmin,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAuthenticated) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const SignageAdminPage(),
            ),
          ] else if (isAdminApp) ...[
            GoRoute(
              path: AppRoutes.login,
              name: AppRouteNames.login,
              builder: (context, state) => const LoginPage(),
            ),
            GoRoute(
              path: AppRoutes.account,
              name: AppRouteNames.account,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAdmin) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const AccountPage(),
            ),
            GoRoute(
              path: AppRoutes.adminDashboard,
              name: AppRouteNames.adminDashboard,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAdmin) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const AdminDashboardPage(),
            ),
            GoRoute(
              path: AppRoutes.billing,
              redirect: (context, state) => AppRoutes.adminBilling,
            ),
            GoRoute(
              path: AppRoutes.adminBilling,
              name: AppRouteNames.adminBilling,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAdmin) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const AdminBillingPage(),
            ),
            GoRoute(
              path: AppRoutes.adminSignage,
              name: AppRouteNames.adminSignage,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAdmin) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const AdminSignagePage(),
            ),
            GoRoute(
              path: AppRoutes.adminProductGallery,
              name: AppRouteNames.adminProductGallery,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAdmin) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const AdminProductGalleryPage(),
            ),
            GoRoute(
              path: AppRoutes.home,
              redirect: (context, state) => AppRoutes.adminDashboard,
            ),
          ],
          if (isAdbApp) ...[
            GoRoute(
              path: AppRoutes.login,
              name: AppRouteNames.login,
              builder: (context, state) => const LoginPage(),
            ),
            GoRoute(
              path: AppRoutes.adbManager,
              name: AppRouteNames.adbManager,
              redirect: (context, state) {
                final authCubit = context.read<AuthCubit>();
                if (!authCubit.state.isAuthenticated) {
                  return AppRoutes.login;
                }
                return null;
              },
              builder: (context, state) => const AdbManagerPage(),
            ),
            GoRoute(
              path: AppRoutes.home,
              redirect: (context, state) => AppRoutes.adbManager,
            ),
          ],
        ],
      ),
    ],
  );
}

String _initialLocationFor(AppExperience experience, AuthState authState) {
  if (experience == AppExperience.admin) {
    return AppRoutes.adminDashboard;
  }
  if (experience == AppExperience.adb) {
    return authState.isAuthenticated ? AppRoutes.adbManager : AppRoutes.login;
  }
  return authState.isAuthenticated ? AppRoutes.billing : AppRoutes.home;
}

class _AuthRouterRefreshNotifier extends ChangeNotifier {
  _AuthRouterRefreshNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouter = createAppRouter(AppExperience.user);

class CostikStudioShell extends StatelessWidget {
  const CostikStudioShell({
    super.key,
    required this.experience,
    required this.child,
  });

  final AppExperience experience;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isAdminApp = experience == AppExperience.admin;
    final isAdbApp = experience == AppExperience.adb;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // ADB App: clean layout — login gets bare scaffold, manager gets mini appbar
        if (isAdbApp) {
          if (location == AppRoutes.login) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: child,
            );
          }
          return Scaffold(
            backgroundColor: const Color(0xFFF1F5F9),
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/logo/costik-studio-logo.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, _) =>
                          const Icon(Icons.adb_rounded, size: 24),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'ADB Manager',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              actions: [
                if (authState.isAuthenticated) ...[
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      context.read<AuthCubit>().logout();
                      context.go(AppRoutes.login);
                    },
                    child: const Text('Keluar'),
                  ),
                  const SizedBox(width: 12),
                ],
              ],
            ),
            body: child,
          );
        }

        final navItems = isAdminApp
            ? const [
                _NavItem('Dashboard', AppRoutes.adminDashboard),
                _NavItem('Billing', AppRoutes.adminBilling),
                _NavItem('Signage', AppRoutes.adminSignage),
                _NavItem('Gallery', AppRoutes.adminProductGallery),
                _NavItem('Account', AppRoutes.account),
              ]
            : [
                const _NavItem('Home', AppRoutes.home),
                const _NavItem('Products', AppRoutes.products),
                if (authState.isAuthenticated) ...[
                  const _NavItem('Dashboard', AppRoutes.billing),
                  const _NavItem('Account', AppRoutes.account),
                ],
              ];

        if (isAdminApp && location != AppRoutes.login) {
          return Scaffold(
            backgroundColor: const Color(
              0xFFF1F5F9,
            ), // Subtle dashboard background
            body: Row(
              children: [
                _AdminSidebar(
                  location: location,
                  navItems: navItems,
                  authState: authState,
                ),
                Expanded(child: child),
              ],
            ),
          );
        }

        if (location == AppRoutes.login) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: child,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () => context.go(AppRoutes.home),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/logo/costik-studio-logo.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, _, _) =>
                          const Icon(Icons.layers_rounded, size: 28),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'CostikStudio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              for (final item in navItems)
                _HeaderNavButton(
                  label: item.label,
                  path: item.path,
                  location: location,
                  isSelected: location == item.path,
                ),
              const SizedBox(width: 8),
              if (authState.isAuthenticated) ...[
                Icon(
                  authState.isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.person_rounded,
                  size: 20,
                ),
                const SizedBox(width: 6),
                OutlinedButton(
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                    context.go(AppRoutes.home);
                  },
                  child: const Text('Keluar'),
                ),
              ] else
                ElevatedButton.icon(
                  key: const Key('header_login_button'),
                  onPressed: () => context.go(AppRoutes.login),
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Login'),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: child,
        );
      },
    );
  }
}

class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final linkStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Colors.white.withValues(alpha: 0.72),
      height: 1.9,
      fontWeight: FontWeight.w600,
    );

    return Container(
      width: double.infinity,
      color: const Color(0xFF07111F),
      padding: const EdgeInsets.fromLTRB(24, 42, 24, 26),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 760;
                  final columns = [
                    _FooterBrand(linkStyle: linkStyle),
                    _FooterColumn(
                      title: 'Quick Links',
                      links: const ['Home', 'Products', 'Login'],
                      linkStyle: linkStyle,
                    ),
                    _FooterColumn(
                      title: 'Product',
                      links: const ['Apps', 'Billing', 'Support'],
                      linkStyle: linkStyle,
                    ),
                    _FooterColumn(
                      title: 'Legal',
                      links: const [
                        'Privacy Policy',
                        'Terms of Service',
                        'Refund Policy',
                      ],
                      linkStyle: linkStyle,
                    ),
                    _FooterContact(linkStyle: linkStyle),
                  ];

                  return Wrap(
                    spacing: isWide ? 56 : 28,
                    runSpacing: 28,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      for (final column in columns)
                        SizedBox(
                          width: isWide ? 180 : double.infinity,
                          child: column,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              Divider(color: Colors.white.withValues(alpha: 0.12)),
              const SizedBox(height: 18),
              Text(
                '© 2026 CostikStudio - Costik Digital Solutions. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand({required this.linkStyle});

  final TextStyle? linkStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              Text(
                'CostikStudio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Simple business app portal for subscriptions, downloads, billing, and support across Costik products.',
            style: linkStyle,
          ),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    required this.links,
    required this.linkStyle,
  });

  final String title;
  final List<String> links;
  final TextStyle? linkStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(link, style: linkStyle),
          ),
      ],
    );
  }
}

class _FooterContact extends StatelessWidget {
  const _FooterContact({required this.linkStyle});

  final TextStyle? linkStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contact',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Text('support@costikstudio.com', style: linkStyle),
        Text('Kendari, Indonesia', style: linkStyle),
      ],
    );
  }
}

class _HeaderNavButton extends StatelessWidget {
  const _HeaderNavButton({
    required this.label,
    required this.path,
    required this.location,
    required this.isSelected,
  });

  final String label;
  final String path;
  final String location;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: ValueKey('header_nav_$path'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(40, 36),
      ),
      onPressed: () {
        if (path == AppRoutes.products && location == AppRoutes.home) {
          HomePage.scrollToProducts();
          return;
        }
        context.go(path);
      },
      child: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.path);

  final String label;
  final String path;
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.location,
    required this.navItems,
    required this.authState,
  });

  final String location;
  final List<_NavItem> navItems;
  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/logo/costik-studio-logo.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, _) =>
                      const Icon(Icons.layers_rounded, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              const Flexible(
                child: Text(
                  'Admin Panel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'MENU',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in navItems) ...[
            _AdminSidebarItem(
              label: item.label,
              path: item.path,
              isSelected: location == item.path,
              icon: _getIconForPath(item.path),
            ),
            const SizedBox(height: 4),
          ],
          const Spacer(),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Admin Active',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent,
              elevation: 0,
            ),
            onPressed: () {
              context.read<AuthCubit>().logout();
              context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  IconData _getIconForPath(String path) {
    if (path.contains('dashboard')) return Icons.dashboard_rounded;
    if (path.contains('billing')) return Icons.account_balance_wallet_rounded;
    if (path.contains('signage')) return Icons.cast_connected_rounded;
    if (path.contains('gallery')) return Icons.photo_library_rounded;
    if (path.contains('account')) return Icons.person_rounded;
    return Icons.circle_rounded;
  }
}

class _AdminSidebarItem extends StatelessWidget {
  const _AdminSidebarItem({
    required this.label,
    required this.path,
    required this.isSelected,
    required this.icon,
  });

  final String label;
  final String path;
  final bool isSelected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.blue : Colors.grey.shade700;

    return Material(
      color: isSelected
          ? Colors.blue.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.go(path),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

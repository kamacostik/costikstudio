import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/account/view/account_page.dart';
import 'package:costikstudio/features/apps/view/apps_page.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/auth/view/login_page.dart';
import 'package:costikstudio/features/billing/view/admin_billing_page.dart';
import 'package:costikstudio/features/billing/view/billing_dashboard_page.dart';
import 'package:costikstudio/features/home/view/home_page.dart';
import 'package:costikstudio/features/payment_return/view/payment_return_page.dart';
import 'package:costikstudio/features/product_detail/view/product_detail_page.dart';
import 'package:costikstudio/features/products/view/products_page.dart';
import 'package:costikstudio/features/signage/view/signage_admin_page.dart';
import 'package:costikstudio/features/subscription/view/iptv_subscription_page.dart';
import 'package:costikstudio/features/subscription/view/signage_subscription_page.dart';
import 'package:costikstudio/features/support/view/support_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

GoRouter createAppRouter(AppExperience experience) {
  final isAdminApp = experience == AppExperience.admin;

  return GoRouter(
    initialLocation: isAdminApp ? AppRoutes.adminBilling : AppRoutes.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            CostikStudioShell(experience: experience, child: child),
        routes: [
          if (!isAdminApp) ...[
            GoRoute(
              path: AppRoutes.home,
              name: AppRouteNames.home,
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: AppRoutes.products,
              name: AppRouteNames.products,
              builder: (context, state) => const ProductsPage(),
            ),
            GoRoute(
              path: AppRoutes.subscribeIptv,
              name: AppRouteNames.subscribeIptv,
              builder: (context, state) => const IptvSubscriptionPage(),
            ),
            GoRoute(
              path: AppRoutes.subscribeSignage,
              name: AppRouteNames.subscribeSignage,
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
          ] else ...[
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
              path: AppRoutes.home,
              redirect: (context, state) => AppRoutes.adminBilling,
            ),
          ],
        ],
      ),
    ],
  );
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

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final navItems = isAdminApp
            ? const [
                _NavItem('Admin Billing', AppRoutes.adminBilling),
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

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () => context.go(
                isAdminApp ? AppRoutes.adminBilling : AppRoutes.home,
              ),
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
                  Flexible(
                    child: Text(
                      isAdminApp ? 'CostikStudio Admin' : 'CostikStudio',
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
                    context.go(isAdminApp ? AppRoutes.login : AppRoutes.home);
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

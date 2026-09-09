import 'package:costikstudio/app/app_experience.dart';
import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/apps/view/apps_page.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/auth/view/login_page.dart';
import 'package:costikstudio/features/billing/view/admin_billing_page.dart';
import 'package:costikstudio/features/billing/view/billing_dashboard_page.dart';
import 'package:costikstudio/features/home/view/home_page.dart';
import 'package:costikstudio/features/product_detail/view/product_detail_page.dart';
import 'package:costikstudio/features/products/view/products_page.dart';
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
              path: AppRoutes.billing,
              name: AppRouteNames.billing,
              builder: (context, state) => const BillingDashboardPage(),
            ),
            GoRoute(
              path: AppRoutes.adminBilling,
              name: AppRouteNames.adminBilling,
              redirect: (context, state) => AppRoutes.billing,
            ),
            GoRoute(
              path: AppRoutes.support,
              name: AppRouteNames.support,
              builder: (context, state) => const SupportPage(),
            ),
          ] else ...[
            GoRoute(
              path: AppRoutes.login,
              name: AppRouteNames.login,
              builder: (context, state) => const LoginPage(),
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
            ? const [_NavItem('Admin Billing', AppRoutes.adminBilling)]
            : const [
                _NavItem('Home', AppRoutes.home),
                _NavItem('Products', AppRoutes.products),
                _NavItem('Apps', AppRoutes.apps),
                _NavItem('Billing', AppRoutes.billing),
                _NavItem('Support', AppRoutes.support),
              ];

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              onTap: () => context.go(
                isAdminApp ? AppRoutes.adminBilling : AppRoutes.home,
              ),
              child: Text(isAdminApp ? 'CostikStudio Admin' : 'CostikStudio'),
            ),
            actions: [
              for (final item in navItems)
                _HeaderNavButton(
                  label: item.label,
                  path: item.path,
                  isSelected: location == item.path,
                ),
              const SizedBox(width: 8),
              if (authState.isAuthenticated) ...[
                Chip(
                  avatar: Icon(
                    authState.isAdmin
                        ? Icons.admin_panel_settings_rounded
                        : Icons.person_rounded,
                    size: 16,
                  ),
                  label: Text(
                    authState.userEmail ?? '',
                    style: const TextStyle(fontSize: 12),
                  ),
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

class _HeaderNavButton extends StatelessWidget {
  const _HeaderNavButton({
    required this.label,
    required this.path,
    required this.isSelected,
  });

  final String label;
  final String path;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(40, 36),
      ),
      onPressed: () => context.go(path),
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

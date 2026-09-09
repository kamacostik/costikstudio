import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/router/app_routes.dart';
import 'package:costikstudio/features/apps/view/apps_page.dart';
import 'package:costikstudio/features/billing/view/admin_billing_page.dart';
import 'package:costikstudio/features/billing/view/billing_dashboard_page.dart';
import 'package:costikstudio/features/home/view/home_page.dart';
import 'package:costikstudio/features/product_detail/view/product_detail_page.dart';
import 'package:costikstudio/features/products/view/products_page.dart';
import 'package:costikstudio/features/support/view/support_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => CostikStudioShell(child: child),
      routes: [
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
            final product = findProductById(state.pathParameters['id'] ?? '');
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
          path: AppRoutes.billing,
          name: AppRouteNames.billing,
          builder: (context, state) => const BillingDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.adminBilling,
          name: AppRouteNames.adminBilling,
          builder: (context, state) => const AdminBillingPage(),
        ),
        GoRoute(
          path: AppRoutes.support,
          name: AppRouteNames.support,
          builder: (context, state) => const SupportPage(),
        ),
      ],
    ),
  ],
);

class CostikStudioShell extends StatelessWidget {
  const CostikStudioShell({super.key, required this.child});

  final Widget child;

  static const _navItems = [
    _NavItem('Home', AppRoutes.home),
    _NavItem('Products', AppRoutes.products),
    _NavItem('Apps', AppRoutes.apps),
    _NavItem('Billing', AppRoutes.billing),
    _NavItem('Admin Billing', AppRoutes.adminBilling),
    _NavItem('Support', AppRoutes.support),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => context.go(AppRoutes.home),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded),
              SizedBox(width: 10),
              Text('CostikStudio'),
            ],
          ),
        ),
        actions: [
          for (final item in _navItems)
            _HeaderNavButton(
              label: item.label,
              path: item.path,
              isSelected: location == item.path,
            ),
          const SizedBox(width: 18),
        ],
      ),
      body: child,
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

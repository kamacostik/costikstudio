import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/features/apps/view/apps_page.dart';
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
          path: '/',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/products',
          name: 'products',
          builder: (context, state) => const ProductsPage(),
        ),
        GoRoute(
          path: '/products/:id',
          name: 'product-detail',
          builder: (context, state) {
            final product = findProductById(state.pathParameters['id'] ?? '');
            return ProductDetailPage(product: product);
          },
        ),
        GoRoute(
          path: '/apps',
          name: 'apps',
          builder: (context, state) => const AppsPage(),
        ),
        GoRoute(path: '/downloads', redirect: (context, state) => '/apps'),
        GoRoute(
          path: '/support',
          name: 'support',
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
    _NavItem('Home', '/'),
    _NavItem('Products', '/products'),
    _NavItem('Apps', '/apps'),
    _NavItem('Support', '/support'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => context.go('/'),
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

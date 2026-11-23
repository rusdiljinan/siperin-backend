import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive.dart';
import 'app_sidebar.dart';

class AppScaffoldShell extends StatelessWidget {
  final int selectedIndex;
  final Widget child;
  final String? title;

  const AppScaffoldShell({
    super.key,
    required this.selectedIndex,
    required this.child,
    this.title,
  });

  static const _routes = [
    '/dashboard',
    '/inventaris',
    '/perbaikan',
    '/aktivitas',
    '/profile',
    '/users',
  ];

  void _navigate(BuildContext context, int index) {
    if (index >= 0 && index < _routes.length) {
      context.go(_routes[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ RESPONSIVE FIX: Force rebuild on orientation changes
    // This ensures sidebar is hidden/shown correctly when device rotates
    return OrientationBuilder(
      builder: (context, orientation) {
        return _buildScaffold(context, orientation);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Orientation orientation) {
    // ✅ RESPONSIVE FIX: Use >= 1024 breakpoint for sidebar (not >= 600)
    final isDesktop = Responsive.isDesktop(context);
    final location = GoRouterState.of(context).uri.toString();
    final currentBase = (selectedIndex >= 0 && selectedIndex < _routes.length)
        ? _routes[selectedIndex]
        : null;
    final showBack =
        currentBase != null &&
        location.startsWith(currentBase) &&
        location != currentBase;

    Future<void> logout() async {
      await context.read<AuthProvider>().logout();
      if (context.mounted) context.go('/login');
    }

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(
              selectedIndex: selectedIndex,
              onLogout: logout,
              onNavigate: (index) => _navigate(context, index),
            ),
            Expanded(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: title != null
                        ? Material(
                            key: ValueKey<String?>(title),
                            color: Theme.of(context).colorScheme.surface,
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    if (showBack)
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back),
                                        onPressed: () {
                                          if (context.canPop()) {
                                            context.pop();
                                          } else {
                                            // fallback to base route
                                            _navigate(context, selectedIndex);
                                          }
                                        },
                                      ),
                                    Text(
                                      title!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('no-title')),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: AppSidebar(
          selectedIndex: selectedIndex,
          onLogout: () {
            Navigator.of(context).pop();
            logout();
          },
          onNavigate: (i) {
            Navigator.of(context).pop();
            _navigate(context, i);
          },
        ),
      ),
      appBar: title != null
          ? AppBar(
              leading: showBack
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          _navigate(context, selectedIndex);
                        }
                      },
                    )
                  : Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Text(
                  title!,
                  key: ValueKey(title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              actions: showBack && Responsive.isMobile(context)
                  ? [
                      Builder(
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                    ]
                  : null,
            )
          : null,
      body: child,
    );
  }
}

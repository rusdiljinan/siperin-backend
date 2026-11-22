import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';

class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final VoidCallback onLogout;
  final void Function(int index)? onNavigate;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onLogout,
    this.onNavigate,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  static const _menus = [
    (0, Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
    (1, Icons.inventory_2_outlined, 'Inventaris', '/inventaris'),
    (2, Icons.build_circle_outlined, 'Perbaikan', '/perbaikan'),
    (3, Icons.history, 'Riwayat', '/aktivitas'),
    (4, Icons.person_outline, 'Profile', '/profile'),
    (5, Icons.manage_accounts_outlined, 'Mengelola Pengguna', '/users'),
  ];

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().user?.role == 'admin';

    return AnimatedContainer(
      width: 260,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      color: AppColors.primaryDark,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance,
                  color: AppColors.white,
                  size: 42,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        AppConstants.instansiName,
                        style: TextStyle(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ..._menus
                    .where((menu) => menu.$1 != 5 || isAdmin)
                    .map(
                      (m) => _SidebarTile(
                        index: m.$1,
                        icon: m.$2,
                        label: m.$3,
                        route: m.$4,
                        selected: widget.selectedIndex == m.$1,
                        onNavigate: widget.onNavigate,
                      ),
                    ),
              ],
            ),
          ),
          _SidebarLogoutTile(onLogout: widget.onLogout),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  final int index;
  final IconData icon;
  final String label;
  final String route;
  final bool selected;
  final void Function(int index)? onNavigate;

  const _SidebarTile({
    required this.index,
    required this.icon,
    required this.label,
    required this.route,
    required this.selected,
    this.onNavigate,
  });

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.paleGold
                : _hovered
                ? AppColors.silk.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: ListTile(
              leading: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  widget.icon,
                  key: ValueKey('${widget.index}-${widget.selected}'),
                  color: widget.selected ? AppColors.charcoal : AppColors.silk,
                ),
              ),
              title: Text(
                widget.label,
                style: TextStyle(
                  color: widget.selected ? AppColors.charcoal : AppColors.silk,
                  fontWeight: widget.selected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              onTap: () {
                if (widget.onNavigate != null) {
                  widget.onNavigate!(widget.index);
                } else {
                  context.go(widget.route);
                }
              },
              dense: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarLogoutTile extends StatefulWidget {
  final VoidCallback onLogout;

  const _SidebarLogoutTile({required this.onLogout});

  @override
  State<_SidebarLogoutTile> createState() => _SidebarLogoutTileState();
}

class _SidebarLogoutTileState extends State<_SidebarLogoutTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: ListTile(
            leading: Icon(
              Icons.logout,
              color: _hovered ? AppColors.white : Colors.white70,
            ),
            title: Text(
              'Logout',
              style: TextStyle(
                color: _hovered ? AppColors.white : Colors.white70,
              ),
            ),
            onTap: widget.onLogout,
          ),
        ),
      ),
    );
  }
}

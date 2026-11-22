import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/router/route_meta.dart';
import 'app_scaffold_shell.dart';

/// Shell utama: sidebar/drawer tetap, konten beranimasi via go_router.
class MainAppShell extends StatelessWidget {
  final Widget child;

  const MainAppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final meta = RouteMeta.fromLocation(location);

    return AppScaffoldShell(
      selectedIndex: meta.selectedIndex,
      title: meta.title,
      child: child,
    );
  }
}

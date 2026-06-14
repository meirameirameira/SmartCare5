import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.home_outlined,    activeIcon: Icons.home,            label: 'Home',      path: '/home'),
    (icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Entrega',  path: '/delivery'),
    (icon: Icons.videocam_outlined, activeIcon: Icons.videocam,       label: 'Consulta',  path: '/consulta'),
    (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart,     label: 'Analytics', path: '/analytics'),
    (icon: Icons.smart_toy_outlined, activeIcon: Icons.smart_toy,     label: 'IA',        path: '/chat'),
    (icon: Icons.map_outlined,      activeIcon: Icons.map,            label: 'Mapa',      path: '/map'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _tabs.indexWhere((t) => location.startsWith(t.path));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon),
          selectedIcon: Icon(t.activeIcon),
          label: t.label,
        )).toList(),
      ),
    );
  }
}

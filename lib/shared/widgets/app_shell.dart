import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static final _tabs = [
    (label: 'Descobrir', icon: Icons.explore_outlined, route: AppRoutes.discover),
    (label: 'Matches', icon: Icons.favorite_outline, route: AppRoutes.matches),
    (label: 'Meu Rebanho', icon: Icons.format_list_bulleted_outlined, route: AppRoutes.herd),
    (label: 'Perfil', icon: Icons.account_circle_outlined, route: AppRoutes.profile),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].route) &&
          (_tabs[i].route != AppRoutes.discover || location == AppRoutes.discover)) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => context.go(_tabs[index].route),
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon, color: AppColors.muted),
                selectedIcon: Icon(tab.icon, color: AppColors.primary),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

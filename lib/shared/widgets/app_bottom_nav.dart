import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

abstract final class AppNavTabs {
  static final tabs = [
    (label: 'Descobrir', icon: Icons.explore_outlined, route: AppRoutes.discover),
    (label: 'Matches', icon: Icons.favorite_outline, route: AppRoutes.matches),
    (label: 'Meu Rebanho', icon: Icons.format_list_bulleted_outlined, route: AppRoutes.herd),
    (label: 'Perfil', icon: Icons.account_circle_outlined, route: AppRoutes.profile),
  ];

  static int selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].route) &&
          (tabs[i].route != AppRoutes.discover || location == AppRoutes.discover)) {
        return i;
      }
    }
    return 0;
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: AppNavTabs.selectedIndex(context),
      onDestinationSelected: (index) => context.go(AppNavTabs.tabs[index].route),
      destinations: AppNavTabs.tabs
          .map(
            (tab) => NavigationDestination(
              icon: Icon(tab.icon, color: AppColors.muted),
              selectedIcon: Icon(tab.icon, color: AppColors.primary),
              label: tab.label,
            ),
          )
          .toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/shared/widgets/app_bottom_nav.dart';

Future<int> _selectedIndexAt(WidgetTester tester, String location) async {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: AppRoutes.discover, builder: (_, _) => const _Screen()),
      GoRoute(path: AppRoutes.matches, builder: (_, _) => const _Screen()),
      GoRoute(path: AppRoutes.herd, builder: (_, _) => const _Screen()),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const _Screen()),
      GoRoute(path: AppRoutes.addAnimal, builder: (_, _) => const _Screen()),
      GoRoute(
        path: AppRoutes.myAnimalDetail,
        builder: (_, _) => const _Screen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pump();

  final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
  return navBar.selectedIndex;
}

class _Screen extends StatelessWidget {
  const _Screen();
  @override
  Widget build(BuildContext context) =>
      Scaffold(bottomNavigationBar: const AppBottomNav());
}

void main() {
  group('AppNavTabs.selectedIndex', () {
    testWidgets('discover (/) selects index 0', (tester) async {
      expect(await _selectedIndexAt(tester, AppRoutes.discover), 0);
    });

    testWidgets('matches selects index 1', (tester) async {
      expect(await _selectedIndexAt(tester, AppRoutes.matches), 1);
    });

    testWidgets('herd (/rebanho) selects index 2', (tester) async {
      expect(await _selectedIndexAt(tester, AppRoutes.herd), 2);
    });

    testWidgets('profile selects index 3', (tester) async {
      expect(await _selectedIndexAt(tester, AppRoutes.profile), 3);
    });

    testWidgets(
        'regression: a route under /rebanho/* (prefix match) does NOT '
        'false-positive-highlight herd via the generic prefix check, and '
        'does NOT fall through to the discover exact-match special case '
        'either — it correctly resolves to the herd tab (index 2) via its '
        'own prefix match', (tester) async {
      expect(await _selectedIndexAt(tester, AppRoutes.addAnimal), 2);
    });

    testWidgets(
        'regression: any non-discover route does not false-positive as '
        'discover (the exact-match special case guarding against prefix '
        'matching "/" against everything)', (tester) async {
      // "/rebanho/animal/abc" starts with "/" (discover's route) but must
      // resolve to herd (its own, more specific route), not discover.
      final router = GoRouter(
        initialLocation: '/rebanho/animal/abc123',
        routes: [
          GoRoute(path: AppRoutes.discover, builder: (_, _) => const _Screen()),
          GoRoute(
            path: AppRoutes.myAnimalDetail,
            builder: (_, _) => const _Screen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, 2); // herd, not discover (index 0)
    });
  });
}

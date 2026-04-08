import 'package:go_router/go_router.dart';

import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/register_screen.dart';
import '../../features/discover/ui/discover_screen.dart';
import '../../features/herd/ui/add_animal_screen.dart';
import '../../features/herd/ui/herd_screen.dart';
import '../../features/matches/ui/matches_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/profile/ui/profile_screen.dart';
import '../../shared/widgets/app_shell.dart';

abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const discover = '/';
  static const matches = '/matches';
  static const herd = '/rebanho';
  static const addAnimal = '/rebanho/novo';
  static const profile = '/perfil';
}

final appRouter = GoRouter(
  // TODO: check Hive for 'hasSeenOnboarding' + auth token to skip screens
  initialLocation: AppRoutes.onboarding,
  routes: [
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (_, _) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, _) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.addAnimal,
      builder: (_, _) => const AddAnimalScreen(),
    ),
    ShellRoute(
      builder: (_, _, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.discover,
          pageBuilder: (_, _) =>
              const NoTransitionPage(child: DiscoverScreen()),
        ),
        GoRoute(
          path: AppRoutes.matches,
          pageBuilder: (_, _) =>
              const NoTransitionPage(child: MatchesScreen()),
        ),
        GoRoute(
          path: AppRoutes.herd,
          pageBuilder: (_, _) => const NoTransitionPage(child: HerdScreen()),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (_, _) =>
              const NoTransitionPage(child: ProfileScreen()),
        ),
      ],
    ),
  ],
);

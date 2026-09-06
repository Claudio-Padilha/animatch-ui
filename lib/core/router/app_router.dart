import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/notification_service.dart';

import '../../features/auth/ui/login_screen.dart';
import '../../features/auth/ui/register_screen.dart';
import '../../shared/domain/animal_detail_data.dart';
import '../../shared/screens/animal_detail_screen.dart';
import '../../features/discover/ui/discover_screen.dart';
import '../../features/herd/ui/add_animal_screen.dart';
import '../../features/herd/ui/edit_animal_screen.dart';
import '../../features/herd/ui/herd_screen.dart';
import '../../features/herd/ui/my_animal_detail_screen.dart';
import '../../features/matches/ui/chat_screen.dart';
import '../../features/matches/ui/match_detail_screen.dart';
import '../../features/matches/ui/matches_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/profile/ui/edit_profile_screen.dart';
import '../../features/profile/ui/profile_completion_screen.dart';
import '../../features/profile/ui/profile_screen.dart';
import '../../features/profile/ui/profile_verification_screen.dart';
import '../../shared/widgets/app_shell.dart';
import 'router_notifier.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const discover = '/';
  static const animalDetail = '/animal/:animalId';
  static String animalDetailPath(String animalId) =>
      '/animal/${Uri.encodeComponent(animalId)}';
  static const matches = '/matches';
  static const matchDetail = '/matches/:matchId';
  static String matchDetailPath(String matchId) =>
      '/matches/${Uri.encodeComponent(matchId)}';
  static const matchChat = '/matches/:matchId/chat';
  static String matchChatPath(String matchId) =>
      '/matches/${Uri.encodeComponent(matchId)}/chat';
  // `side` is 'yours' | 'theirs' — the other breeder's animal can't be fetched
  // by its own id anymore (owner-only), so it's recovered from the match.
  static const matchAnimalDetail = '/matches/:matchId/animal/:side';
  static String matchAnimalDetailPath(String matchId, String side) =>
      '/matches/${Uri.encodeComponent(matchId)}/animal/$side';
  static const herd = '/rebanho';
  static const addAnimal = '/rebanho/novo';
  static const myAnimalDetail = '/rebanho/animal/:animalId';
  static String myAnimalDetailPath(String animalId) =>
      '/rebanho/animal/${Uri.encodeComponent(animalId)}';
  static const editAnimal = '/rebanho/animal/editar/:animalId';
  static String editAnimalPath(String animalId) =>
      '/rebanho/animal/editar/${Uri.encodeComponent(animalId)}';
  static const profileCompletion = '/completar-perfil';
  static const profile = '/perfil';
  static const editProfile = '/perfil/editar';
  static const profileVerification = '/perfil/verificacao';
}

void _handleNotificationTap(RemoteMessage message, GoRouter router) {
  final type = message.data['type'] as String?;
  if (type != 'match_confirmed' && type != 'new_message') return;

  // Deep-link straight to the match when the payload carries its id; the
  // detail/chat screens fetch it fresh, so no in-memory match is needed.
  final matchId = message.data['matchId'] as String?;
  if (matchId != null && matchId.isNotEmpty) {
    router.go(AppRoutes.matches);
    router.push(AppRoutes.matchDetailPath(matchId));
    return;
  }
  router.go(AppRoutes.matches);
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);
  final router = GoRouter(
    refreshListenable: notifier,
    redirect: notifier.redirect,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, state) => OnboardingScreen(
          errorMessage: state.extra as String?,
        ),
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
      GoRoute(
        path: AppRoutes.editAnimal,
        builder: (_, state) => EditAnimalScreen(
          animalId: state.pathParameters['animalId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.myAnimalDetail,
        builder: (_, state) => MyAnimalDetailScreen(
          animalId: state.pathParameters['animalId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.profileCompletion,
        builder: (_, _) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileVerification,
        builder: (_, _) => const ProfileVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.animalDetail,
        builder: (_, state) => AnimalDetailLoader(
          animalId: state.pathParameters['animalId']!,
          animal: state.extra as AnimalDetailData?,
        ),
      ),
      // Match routes are keyed off the match id and load fresh from
      // GET /matches/:id (see matchDetailProvider), so a deep link /
      // notification tap / OS state restoration with no `extra` recovers
      // cleanly instead of crashing.
      GoRoute(
        path: AppRoutes.matchAnimalDetail,
        builder: (_, state) => MatchAnimalDetailLoader(
          matchId: state.pathParameters['matchId']!,
          side: state.pathParameters['side']!,
          animal: state.extra as AnimalDetailData?,
        ),
      ),
      GoRoute(
        path: AppRoutes.matchChat,
        builder: (_, state) => ChatScreen(
          matchId: state.pathParameters['matchId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.matchDetail,
        builder: (_, state) => MatchDetailScreen(
          matchId: state.pathParameters['matchId']!,
        ),
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

  if (!kIsWeb) {
    final notificationService = ref.read(notificationServiceProvider);

    // Handle notification tap when app was terminated (cold start).
    notificationService.getInitialMessage().then((message) {
      if (message != null) _handleNotificationTap(message, router);
    });

    // Handle notification tap when app was in background.
    final msgSub = notificationService.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message, router);
    });

    // Handle tap on a local notification shown while app was in foreground.
    final tapSub = notificationService.onLocalTap.listen((route) {
      if (route != null) router.go(route);
    });

    ref.onDispose(() {
      msgSub.cancel();
      tapSub.cancel();
    });
  }

  return router;
});

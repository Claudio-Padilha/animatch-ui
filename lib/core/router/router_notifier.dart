import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/onboarding/providers/onboarding_provider.dart';
import 'app_router.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<dynamic>(authNotifierProvider, (prev, next) => notifyListeners());
    _ref.listen<bool>(authInitializedProvider, (prev, next) => notifyListeners());
    _ref.listen<bool>(hasSeenOnboardingProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final initialized = _ref.read(authInitializedProvider);
    final loc = state.matchedLocation;

    // Wait on splash until session check completes.
    if (!initialized) return loc == AppRoutes.splash ? null : AppRoutes.splash;

    final breeder = _ref.read(authNotifierProvider);
    final isLoggedIn = breeder != null;

    final isPublic = loc == AppRoutes.onboarding ||
        loc == AppRoutes.login ||
        loc == AppRoutes.register;

    if (!isLoggedIn) {
      if (loc == AppRoutes.splash || !isPublic) {
        final hasSeenOnboarding = _ref.read(hasSeenOnboardingProvider);
        return hasSeenOnboarding ? AppRoutes.login : AppRoutes.onboarding;
      }
      return null;
    }

    // Logged in
    final needsCompletion = breeder.city == null || breeder.city!.trim().isEmpty;

    if (loc == AppRoutes.splash) {
      return needsCompletion ? AppRoutes.profileCompletion : AppRoutes.herd;
    }
    if (needsCompletion && loc != AppRoutes.profileCompletion) {
      return AppRoutes.profileCompletion;
    }
    if (!needsCompletion &&
        (isPublic || loc == AppRoutes.profileCompletion)) {
      return AppRoutes.herd;
    }
    if (loc == AppRoutes.editProfile && !breeder.verifiedBreeder) {
      return AppRoutes.profile;
    }

    return null;
  }
}

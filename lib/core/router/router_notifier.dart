import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import 'app_router.dart';

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<dynamic>(authNotifierProvider, (prev, next) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final breeder = _ref.read(authNotifierProvider);
    final isLoggedIn = breeder != null;
    final loc = state.matchedLocation;

    final isPublic = loc == AppRoutes.onboarding ||
        loc == AppRoutes.login ||
        loc == AppRoutes.register;

    if (!isLoggedIn && !isPublic) return AppRoutes.onboarding;

    if (isLoggedIn) {
      final needsCompletion =
          breeder.city == null || breeder.city!.trim().isEmpty;
      if (needsCompletion && loc != AppRoutes.profileCompletion) {
        return AppRoutes.profileCompletion;
      }
      if (!needsCompletion &&
          (isPublic || loc == AppRoutes.profileCompletion)) {
        return AppRoutes.discover;
      }
      if (loc == AppRoutes.editProfile && !breeder.verifiedBreeder) {
        return AppRoutes.profile;
      }
    }

    return null;
  }
}

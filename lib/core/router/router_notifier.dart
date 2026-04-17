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
    final isLoggedIn = _ref.read(authNotifierProvider) != null;
    final loc = state.matchedLocation;

    final isPublic = loc == AppRoutes.onboarding ||
        loc == AppRoutes.login ||
        loc == AppRoutes.register;

    if (!isLoggedIn && !isPublic) return AppRoutes.onboarding;
    if (isLoggedIn && isPublic) return AppRoutes.discover;
    return null;
  }
}

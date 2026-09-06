import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/core/router/router_notifier.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/onboarding/providers/onboarding_provider.dart';

import '../helpers/fakes.dart';

// Wraps RouterNotifier in a trivial Provider so a test can obtain one backed
// by a real Ref (RouterNotifier isn't itself constructible without one).
final _routerNotifierProvider = Provider<RouterNotifier>(RouterNotifier.new);

class _Marker extends StatelessWidget {
  const _Marker(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(label);
}

// A minimal standalone GoRouter — real screens aren't used so these tests
// stay decoupled from screen-level dependencies (Firebase, Dio, etc.) and
// only exercise RouterNotifier.redirect's actual decision logic.
GoRouter _buildRouter(
  ProviderContainer container, {
  String initialLocation = AppRoutes.splash,
}) {
  final notifier = container.read(_routerNotifierProvider);
  return GoRouter(
    refreshListenable: notifier,
    redirect: notifier.redirect,
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const _Marker('splash')),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const _Marker('onboarding')),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const _Marker('login')),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const _Marker('register')),
      GoRoute(
        path: AppRoutes.profileCompletion,
        builder: (_, _) => const _Marker('profileCompletion'),
      ),
      GoRoute(path: AppRoutes.herd, builder: (_, _) => const _Marker('herd')),
      GoRoute(path: AppRoutes.profile, builder: (_, _) => const _Marker('profile')),
      GoRoute(path: AppRoutes.editProfile, builder: (_, _) => const _Marker('editProfile')),
    ],
  );
}

const _breederNoCity = Breeder(id: '1', name: 'A', email: 'a@x.com');
const _breederUnverified =
    Breeder(id: '1', name: 'A', email: 'a@x.com', city: 'Uberaba'); // status defaults to pending
const _breederVerified = Breeder(
  id: '1',
  name: 'A',
  email: 'a@x.com',
  city: 'Uberaba',
  status: BreederStatus.active,
);

Future<void> _pumpRouter(WidgetTester tester, GoRouter router) =>
    tester.pumpWidget(MaterialApp.router(routerConfig: router));

void main() {
  testWidgets('stays on splash until auth is initialized', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await _pumpRouter(tester, _buildRouter(container));
    await tester.pump();
    expect(find.text('splash'), findsOneWidget);
  });

  testWidgets('not logged in, never seen onboarding -> onboarding', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(authInitializedProvider.notifier).setInitialized();
    await _pumpRouter(tester, _buildRouter(container));
    await tester.pumpAndSettle();
    expect(find.text('onboarding'), findsOneWidget);
  });

  testWidgets('not logged in, already seen onboarding -> login', (tester) async {
    final container = ProviderContainer(overrides: [
      hasSeenOnboardingProvider
          .overrideWith(() => FakeOnboardingNotifier(initiallySeen: true)),
    ]);
    addTearDown(container.dispose);
    container.read(authInitializedProvider.notifier).setInitialized();
    await _pumpRouter(tester, _buildRouter(container));
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets(
      'not logged in, deep link to a protected route, already seen onboarding -> login',
      (tester) async {
    final container = ProviderContainer(overrides: [
      hasSeenOnboardingProvider
          .overrideWith(() => FakeOnboardingNotifier(initiallySeen: true)),
    ]);
    addTearDown(container.dispose);
    container.read(authInitializedProvider.notifier).setInitialized();
    await _pumpRouter(
      tester,
      _buildRouter(container, initialLocation: AppRoutes.herd),
    );
    await tester.pumpAndSettle();
    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('logged in without a city -> profileCompletion', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(authInitializedProvider.notifier).setInitialized();
    container.read(authNotifierProvider.notifier).updateBreeder(_breederNoCity);
    await _pumpRouter(tester, _buildRouter(container));
    await tester.pumpAndSettle();
    expect(find.text('profileCompletion'), findsOneWidget);
  });

  testWidgets('logged in with a city -> herd', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(authInitializedProvider.notifier).setInitialized();
    container.read(authNotifierProvider.notifier).updateBreeder(_breederVerified);
    await _pumpRouter(tester, _buildRouter(container));
    await tester.pumpAndSettle();
    expect(find.text('herd'), findsOneWidget);
  });

  testWidgets('unverified breeder cannot reach editProfile -> profile (M-4 guard)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(authInitializedProvider.notifier).setInitialized();
    container
        .read(authNotifierProvider.notifier)
        .updateBreeder(_breederUnverified);
    await _pumpRouter(
      tester,
      _buildRouter(container, initialLocation: AppRoutes.editProfile),
    );
    await tester.pumpAndSettle();
    expect(find.text('profile'), findsOneWidget);
  });

  testWidgets('verified breeder can reach editProfile', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(authInitializedProvider.notifier).setInitialized();
    container
        .read(authNotifierProvider.notifier)
        .updateBreeder(_breederVerified);
    await _pumpRouter(
      tester,
      _buildRouter(container, initialLocation: AppRoutes.editProfile),
    );
    await tester.pumpAndSettle();
    expect(find.text('editProfile'), findsOneWidget);
  });
}

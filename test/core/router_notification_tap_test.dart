import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/core/services/notification_service.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/matches/domain/match_item.dart';
import 'package:animatch/features/matches/providers/match_provider.dart';
import 'package:animatch/features/onboarding/providers/onboarding_provider.dart';

import '../helpers/fakes.dart';

// A logged-in, unverified breeder with a city set: passes the "logged in"
// and "profile completion done" redirect gates, isn't blocked from
// /matches specifically (only /perfil/editar is verified-gated), and
// crucially renders MatchesScreen down to a static UnverifiedProfilePrompt
// with no network/Firebase dependency — letting this test exercise the
// real production routerProvider without needing to fake out every screen's
// data dependencies.
const _breeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  city: 'Uberaba',
);

MatchItem _match() => const MatchItem(
      id: 'm1',
      status: MatchStatus.confirmado,
      timeLabel: 'Hoje',
      yourAnimal: MatchAnimal(name: 'Trovão', breed: 'Nelore · Macho'),
      theirAnimal: MatchAnimal(name: 'Estrela', breed: 'Nelore · Fêmea'),
      contact: MatchContact(breederName: 'Fazenda Y', phone: ''),
    );

ProviderContainer _buildContainer({
  required FakeNotificationService notificationService,
  FakeMatchRepository? matchRepository,
}) {
  final container = ProviderContainer(overrides: [
    notificationServiceProvider.overrideWithValue(notificationService),
    authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
    hasSeenOnboardingProvider
        .overrideWith(() => FakeOnboardingNotifier(initiallySeen: true)),
    matchRepositoryProvider.overrideWithValue(
      matchRepository ?? FakeMatchRepository(),
    ),
  ]);
  container.read(authInitializedProvider.notifier).setInitialized();
  return container;
}

void main() {
  group('routerProvider notification-tap wiring', () {
    testWidgets(
        'cold start (getInitialMessage): match_confirmed navigates to '
        '/matches', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notificationService = FakeNotificationService(
        initialMessage: const RemoteMessage(
          data: {'type': 'match_confirmed'},
        ),
      );
      final container =
          _buildContainer(notificationService: notificationService);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      // getInitialMessage() is awaited inside a .then() — needs a couple of
      // microtask/frame cycles to land and drive the redirect.
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Matches')),
        findsOneWidget,
      );
    });

    testWidgets(
        'onMessageOpenedApp: new_message navigates to /matches',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notificationService = FakeNotificationService();
      final container =
          _buildContainer(notificationService: notificationService);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      notificationService.onMessageOpenedAppController.add(
        const RemoteMessage(data: {'type': 'new_message'}),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Matches')),
        findsOneWidget,
      );
    });

    testWidgets(
        'onLocalTap: a foreground local-notification tap navigates to the '
        'given route', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notificationService = FakeNotificationService();
      final container =
          _buildContainer(notificationService: notificationService);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      notificationService.onLocalTapController.add(AppRoutes.matches);
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Matches')),
        findsOneWidget,
      );
    });

    testWidgets(
        'match_confirmed with a matchId in the payload deep-links to that '
        'match', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notificationService = FakeNotificationService();
      final container = _buildContainer(
        notificationService: notificationService,
        matchRepository: FakeMatchRepository(getMatchResult: _match()),
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      notificationService.onMessageOpenedAppController.add(
        const RemoteMessage(data: {'type': 'match_confirmed', 'matchId': 'm1'}),
      );
      await tester.pumpAndSettle();

      expect(find.text('Match Confirmado'), findsOneWidget);
    });

    testWidgets('an unrecognized message type is a no-op', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final notificationService = FakeNotificationService();
      final container =
          _buildContainer(notificationService: notificationService);
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      notificationService.onMessageOpenedAppController.add(
        const RemoteMessage(data: {'type': 'something_else'}),
      );
      await tester.pumpAndSettle();

      // Landed on herd (the default "logged in with a city" redirect
      // target), not matches — the unrecognized type didn't navigate. Both
      // screens render an identical UnverifiedProfilePrompt for this
      // breeder, so distinguish via the AppBar title instead.
      expect(
        find.descendant(
            of: find.byType(AppBar), matching: find.text('Meu Rebanho')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text('Matches')),
        findsNothing,
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/core/services/notification_service.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/herd/domain/animal_enums.dart';
import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/herd/providers/herd_provider.dart';
import 'package:animatch/features/locations/providers/locations_provider.dart';
import 'package:animatch/features/matches/domain/match_item.dart';
import 'package:animatch/features/matches/providers/match_provider.dart';
import 'package:animatch/features/onboarding/providers/onboarding_provider.dart';
import 'package:animatch/shared/domain/municipalities.dart';

import '../helpers/fakes.dart';

// A logged-in, verified breeder with a city: passes every redirect gate so
// deep-linked routes below are reachable directly, isolating this test to
// the route-table/loader behavior itself rather than auth redirects.
const _breeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  city: 'Uberaba',
  status: BreederStatus.active,
);

MatchItem _match({MatchStatus status = MatchStatus.confirmado}) => MatchItem(
      id: 'm1',
      status: status,
      timeLabel: 'Hoje',
      yourAnimal: const MatchAnimal(name: 'Trovão', breed: 'Nelore · Macho'),
      theirAnimal: const MatchAnimal(name: 'Estrela', breed: 'Nelore · Fêmea'),
      contact: const MatchContact(breederName: 'Fazenda Y', phone: ''),
    );

// 480pt wide: standard 390pt iPhone width triggers the already-filed K-4
// overflow bugs in HerdScreen/MyAnimalDetailScreen, which are incidental to
// what these tests actually exercise (route-table/loader behavior).
Future<ProviderContainer> _pumpRealRouter(
  WidgetTester tester, {
  required String initialLocation,
  Object? extra,
  FakeHerdRepository? herdRepository,
  FakeMatchRepository? matchRepository,
}) async {
  tester.view.physicalSize = const Size(480, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      notificationServiceProvider.overrideWithValue(FakeNotificationService()),
      authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
      hasSeenOnboardingProvider
          .overrideWith(() => FakeOnboardingNotifier(initiallySeen: true)),
      herdRepositoryProvider.overrideWithValue(
        herdRepository ?? FakeHerdRepository(getAnimalsResult: const []),
      ),
      matchRepositoryProvider.overrideWithValue(
        matchRepository ?? FakeMatchRepository(),
      ),
      // EditAnimalScreen renders AddressFormFields, which watches this; the
      // real implementation hits the network and never settles in tests.
      municipalitiesProvider
          .overrideWith((ref) async => const Municipalities({})),
    ],
  );
  container.read(authInitializedProvider.notifier).setInitialized();
  addTearDown(container.dispose);

  final router = container.read(routerProvider);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  router.push(initialLocation, extra: extra);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('matchDetail/chat: recover from the match id alone (H-6)', () {
    testWidgets('matchDetailPath with no extra fetches GET /matches/:id and '
        'renders the screen', (tester) async {
      await _pumpRealRouter(
        tester,
        initialLocation: AppRoutes.matchDetailPath('m1'),
        matchRepository: FakeMatchRepository(getMatchResult: _match()),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Match Confirmado'), findsOneWidget);
    });

    testWidgets('matchDetailPath shows an error state when the fetch fails',
        (tester) async {
      await _pumpRealRouter(
        tester,
        initialLocation: AppRoutes.matchDetailPath('m1'),
        matchRepository: FakeMatchRepository(getMatchError: Exception('boom')),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Não foi possível carregar o match'),
          findsOneWidget);
    });

    testWidgets('matchChatPath with a pending match shows the "not confirmed" '
        'state (no Stream Chat call)', (tester) async {
      await _pumpRealRouter(
        tester,
        initialLocation: AppRoutes.matchChatPath('m1'),
        matchRepository: FakeMatchRepository(
          getMatchResult: _match(status: MatchStatus.pendente),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('quando o outro criador confirmar'),
          findsOneWidget);
    });
  });

  group('myAnimalDetail/editAnimal: resolve animalId from pathParameters, '
      'not extra', () {
    testWidgets('myAnimalDetailPath with no extra does not crash — '
        'resolves animalId from the path', (tester) async {
      final repo = FakeHerdRepository(getAnimalsResult: [
        HerdAnimal(
          id: 'a1',
          name: 'Imperador',
          breed: 'Nelore',
          sex: 'Macho',
          species: AnimalSpecies.cattle,
          available: true,
        ),
      ]);

      // No `extra:` passed at all — only the path.
      await _pumpRealRouter(
        tester,
        initialLocation: AppRoutes.myAnimalDetailPath('a1'),
        herdRepository: repo,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Imperador'), findsOneWidget);
    });

    // NOTE: despite the name, this is not actually a declaration-order
    // hazard — `editAnimal` has 4 path segments vs. `myAnimalDetail`'s 3,
    // and go_router only accepts a childless route's match if it consumes
    // the *entire* remaining URL (confirmed against go_router's
    // _matchByNavigatorKeyForGoRoute source), so a 3-segment route can never
    // shadow a 4-segment one regardless of declaration order. See H-6 in
    // docs/production-review.md, which already draws this same conclusion.
    // Kept as a regression test anyway since it still pins the correct
    // resolution (EditAnimalScreen, not MyAnimalDetailScreen with
    // animalId: "editar") — just not for the reason the name implies.
    testWidgets(
        'editAnimalPath resolves to EditAnimalScreen despite the '
        '"/rebanho/animal/" path-prefix shared with myAnimalDetail',
        (tester) async {
      final repo = FakeHerdRepository(getAnimalsResult: [
        HerdAnimal(
          id: 'abc123',
          name: 'Imperador',
          breed: 'Nelore',
          sex: 'Macho',
          species: AnimalSpecies.cattle,
          available: true,
        ),
      ]);

      await _pumpRealRouter(
        tester,
        initialLocation: '/rebanho/animal/editar/abc123',
        herdRepository: repo,
      );

      // Resolves to EditAnimalScreen ("Editar <name>" AppBar title, "Salvar"
      // action), not MyAnimalDetailScreen with animalId literally "editar".
      expect(
        find.descendant(
            of: find.byType(AppBar), matching: find.text('Editar Imperador')),
        findsOneWidget,
      );
    });
  });
}

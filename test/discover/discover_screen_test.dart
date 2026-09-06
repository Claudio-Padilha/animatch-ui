import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/discover/domain/discover_animal.dart';
import 'package:animatch/features/discover/providers/discover_provider.dart';
import 'package:animatch/features/discover/ui/discover_screen.dart';
import 'package:animatch/features/herd/domain/animal_enums.dart';
import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/herd/providers/selected_animal_provider.dart';
import 'package:animatch/features/matches/data/match_repository.dart';
import 'package:animatch/features/matches/providers/match_provider.dart';
import 'package:animatch/shared/domain/animal_detail_data.dart';
import 'package:animatch/shared/widgets/circle_action_button.dart';
import 'package:animatch/shared/widgets/unverified_profile_prompt.dart';

import '../helpers/fakes.dart';

class MockMatchRepository extends Mock implements MatchRepository {}

const _verifiedBreeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  status: BreederStatus.active,
);

final _selected = HerdAnimal(
  id: 'sel1',
  name: 'Trovão',
  breed: 'Nelore',
  sex: 'Macho',
  species: AnimalSpecies.cattle,
  available: true,
);

DiscoverAnimal _candidate({String? pendingMatchId}) => DiscoverAnimal(
      id: 'cand1',
      name: 'Estrela',
      species: 'cattle',
      breed: 'Nelore',
      sex: 'Fêmea',
      photoUrls: const [],
      locationCity: 'Uberaba',
      locationState: 'MG',
      pendingMatchId: pendingMatchId,
    );

Future<void> _pumpDiscoverScreen(
  WidgetTester tester, {
  required MockMatchRepository repo,
  required DiscoverAnimal candidate,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(overrides: [
    authNotifierProvider.overrideWith(() => SeededAuthNotifier(_verifiedBreeder)),
    matchRepositoryProvider.overrideWithValue(repo),
    suggestionsProvider(_selected.id).overrideWith((ref) async => [candidate]),
  ]);
  addTearDown(container.dispose);
  container.read(selectedAnimalProvider.notifier).select(_selected);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: DiscoverScreen()),
    ),
  );
  // Let the suggestionsProvider FutureProvider resolve and the swiper build.
  await tester.pump();
  await tester.pump();
}

Future<void> _tapAction(WidgetTester tester, String label) async {
  final gesture = find.descendant(
    of: find.widgetWithText(CircleActionButton, label),
    matching: find.byType(GestureDetector),
  );
  await tester.tap(gesture);
  // Let the CardSwiper's swipe animation run and onSwipe fire.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  // Flush the (unawaited) _onLike/_onReject future.
  await tester.pump();
  await tester.pump();
}

void main() {
  group('_onLike', () {
    testWidgets(
        'no pendingMatchId: calls createMatch (not confirmMatch); '
        'non-confirmed response does not show the celebration dialog',
        (tester) async {
      final repo = MockMatchRepository();
      when(() => repo.createMatch(
            firstLikeAnimalId: any(named: 'firstLikeAnimalId'),
            secondLikeAnimalId: any(named: 'secondLikeAnimalId'),
          )).thenAnswer((_) async => {'id': 'm1', 'status': 'pending'});

      final candidate = _candidate();
      await _pumpDiscoverScreen(tester, repo: repo, candidate: candidate);
      await _tapAction(tester, 'Curtir');

      verify(() => repo.createMatch(
            firstLikeAnimalId: _selected.id,
            secondLikeAnimalId: candidate.id,
          )).called(1);
      verifyNever(() => repo.confirmMatch(any()));
      expect(find.text('É um Match!'), findsNothing);
    });

    testWidgets(
        'existing pendingMatchId: calls confirmMatch (not createMatch); '
        'confirmed response shows the celebration dialog',
        (tester) async {
      final repo = MockMatchRepository();
      when(() => repo.confirmMatch(any()))
          .thenAnswer((_) async => {'id': 'm1', 'status': 'confirmed'});

      final candidate = _candidate(pendingMatchId: 'pm1');
      await _pumpDiscoverScreen(tester, repo: repo, candidate: candidate);
      await _tapAction(tester, 'Curtir');

      verify(() => repo.confirmMatch('pm1')).called(1);
      verifyNever(() => repo.createMatch(
            firstLikeAnimalId: any(named: 'firstLikeAnimalId'),
            secondLikeAnimalId: any(named: 'secondLikeAnimalId'),
          ));
      expect(find.text('É um Match!'), findsOneWidget);
    });

    testWidgets(
        'network failure shows the Portuguese SnackBar, does not crash',
        (tester) async {
      final repo = MockMatchRepository();
      when(() => repo.createMatch(
            firstLikeAnimalId: any(named: 'firstLikeAnimalId'),
            secondLikeAnimalId: any(named: 'secondLikeAnimalId'),
          )).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/matches'),
          type: DioExceptionType.connectionError,
        ),
      );

      final candidate = _candidate();
      await _pumpDiscoverScreen(tester, repo: repo, candidate: candidate);
      await _tapAction(tester, 'Curtir');

      expect(
        find.text('Não foi possível registrar o like. Tente novamente.'),
        findsOneWidget,
      );
    });
  });

  group('_onReject', () {
    testWidgets('no pendingMatchId: calls createMatch with status: rejected',
        (tester) async {
      final repo = MockMatchRepository();
      when(() => repo.createMatch(
            firstLikeAnimalId: any(named: 'firstLikeAnimalId'),
            secondLikeAnimalId: any(named: 'secondLikeAnimalId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => {'id': 'm2', 'status': 'rejected'});

      final candidate = _candidate();
      await _pumpDiscoverScreen(tester, repo: repo, candidate: candidate);
      await _tapAction(tester, 'Passar');

      verify(() => repo.createMatch(
            firstLikeAnimalId: _selected.id,
            secondLikeAnimalId: candidate.id,
            status: 'rejected',
          )).called(1);
      verifyNever(() => repo.rejectMatch(any()));
    });

    testWidgets('existing pendingMatchId: calls rejectMatch (not createMatch)',
        (tester) async {
      final repo = MockMatchRepository();
      when(() => repo.rejectMatch(any())).thenAnswer((_) async {});

      final candidate = _candidate(pendingMatchId: 'pm2');
      await _pumpDiscoverScreen(tester, repo: repo, candidate: candidate);
      await _tapAction(tester, 'Passar');

      verify(() => repo.rejectMatch('pm2')).called(1);
      verifyNever(() => repo.createMatch(
            firstLikeAnimalId: any(named: 'firstLikeAnimalId'),
            secondLikeAnimalId: any(named: 'secondLikeAnimalId'),
            status: any(named: 'status'),
          ));
    });

    testWidgets(
        'network failure shows the Portuguese SnackBar, does not crash',
        (tester) async {
      final repo = MockMatchRepository();
      when(() => repo.rejectMatch(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/matches/pm3/status'),
          type: DioExceptionType.connectionError,
        ),
      );

      final candidate = _candidate(pendingMatchId: 'pm3');
      await _pumpDiscoverScreen(tester, repo: repo, candidate: candidate);
      await _tapAction(tester, 'Passar');

      expect(
        find.text(
            'Não foi possível registrar a rejeição. Tente novamente.'),
        findsOneWidget,
      );
    });
  });

  group('screen states', () {
    Future<void> pumpState(
      WidgetTester tester, {
      Breeder? breeder = _verifiedBreeder,
      bool selectAnimal = true,
      FutureOr<List<DiscoverAnimal>> Function()? suggestions,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          authNotifierProvider.overrideWith(() => SeededAuthNotifier(breeder)),
          matchRepositoryProvider.overrideWithValue(MockMatchRepository()),
          if (selectAnimal && suggestions != null)
            suggestionsProvider(_selected.id)
                .overrideWith((ref) => suggestions()),
        ],
      );
      addTearDown(container.dispose);
      if (selectAnimal) {
        container.read(selectedAnimalProvider.notifier).select(_selected);
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DiscoverScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('unverified breeder sees UnverifiedProfilePrompt, not the '
        'swipe stack', (tester) async {
      await pumpState(
        tester,
        breeder: const Breeder(id: 'b1', name: 'X', email: 'x@x.com'),
        suggestions: () => [_candidate()],
      );

      expect(find.byType(UnverifiedProfilePrompt), findsOneWidget);
    });

    testWidgets('no animal selected shows the _NoAnimalSelected CTA to herd',
        (tester) async {
      await pumpState(tester, selectAnimal: false);

      expect(find.text('Escolha um animal'), findsOneWidget);
    });

    testWidgets('loading state', (tester) async {
      await pumpState(
        tester,
        suggestions: () => Completer<List<DiscoverAnimal>>().future,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error state', (tester) async {
      await pumpState(
        tester,
        suggestions: () async => throw Exception('boom'),
      );

      expect(
        find.text('Não foi possível carregar sugestões'),
        findsOneWidget,
      );
    });

    testWidgets('no-suggestions (empty list) state', (tester) async {
      await pumpState(tester, suggestions: () => []);

      expect(
        find.text('Sem sugestões de match no momento'),
        findsOneWidget,
      );
    });

    testWidgets('populated: renders the swipe card and selected-animal '
        'banner', (tester) async {
      final candidate = _candidate();
      await pumpState(tester, suggestions: () => [candidate]);

      expect(find.text('Buscando par para: Trovão'), findsOneWidget);
      expect(find.text('Estrela'), findsOneWidget);
    });
  });

  group('card tap navigation and _seenIds bookkeeping', () {
    Future<GoRouter> pumpWithRouter(
      WidgetTester tester, {
      required List<DiscoverAnimal> candidates,
      bool Function()? popResult,
    }) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(overrides: [
        authNotifierProvider.overrideWith(() => SeededAuthNotifier(_verifiedBreeder)),
        matchRepositoryProvider.overrideWithValue(MockMatchRepository()),
        suggestionsProvider(_selected.id).overrideWith((ref) async => candidates),
      ]);
      addTearDown(container.dispose);
      container.read(selectedAnimalProvider.notifier).select(_selected);

      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const DiscoverScreen()),
        GoRoute(
          path: AppRoutes.animalDetail,
          builder: (_, state) => Scaffold(
            appBar: AppBar(title: const Text('animal-detail')),
            body: Text(
              'extra:${(state.extra as AnimalDetailData).name}:'
              '${state.pathParameters['animalId']}',
            ),
          ),
        ),
      ]);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump();
      return router;
    }

    testWidgets('tapping a card pushes animalDetailPath with the id and the '
        "AnimalDetailData.fromDiscoverAnimal extra", (tester) async {
      final candidate = _candidate();
      final router =
          await pumpWithRouter(tester, candidates: [candidate]);

      await tester.tap(find.text(candidate.name));
      await tester.pumpAndSettle();

      expect(router.state.matchedLocation, AppRoutes.animalDetailPath(candidate.id));
      expect(find.text('extra:${candidate.name}:${candidate.id}'), findsOneWidget);
    });

    testWidgets('popping the detail route with true marks the card seen — '
        'the last remaining candidate disappears, showing _NoSuggestions',
        (tester) async {
      final candidate = _candidate();
      final router =
          await pumpWithRouter(tester, candidates: [candidate]);

      await tester.tap(find.text(candidate.name));
      await tester.pumpAndSettle();
      router.pop(true);
      await tester.pumpAndSettle();

      expect(find.text('Sem sugestões de match no momento'), findsOneWidget);
    });

    testWidgets('popping the detail route with false (or null) does not '
        'mark the card seen — it is still shown', (tester) async {
      final candidate = _candidate();
      await pumpWithRouter(tester, candidates: [candidate]);

      await tester.tap(find.text(candidate.name));
      await tester.pumpAndSettle();
      // Real back-navigation (system back / AppBar back), not an explicit
      // pop(true) — result is null.
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Estrela'), findsOneWidget);
      expect(find.text('Sem sugestões de match no momento'), findsNothing);
    });

    testWidgets('swiping a card via the action buttons marks it seen: it '
        "does not reappear, while a second, unswiped candidate still does",
        (tester) async {
      const first = DiscoverAnimal(
        id: 'cand1',
        name: 'Estrela',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Fêmea',
        photoUrls: [],
        locationCity: 'Uberaba',
        locationState: 'MG',
      );
      const second = DiscoverAnimal(
        id: 'cand2',
        name: 'Sultão',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Macho',
        photoUrls: [],
        locationCity: 'Uberaba',
        locationState: 'MG',
      );
      final repo = MockMatchRepository();
      when(() => repo.rejectMatch(any())).thenAnswer((_) async {});
      when(() => repo.createMatch(
            firstLikeAnimalId: any(named: 'firstLikeAnimalId'),
            secondLikeAnimalId: any(named: 'secondLikeAnimalId'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => {'id': 'm3', 'status': 'rejected'});

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(overrides: [
        authNotifierProvider.overrideWith(() => SeededAuthNotifier(_verifiedBreeder)),
        matchRepositoryProvider.overrideWithValue(repo),
        suggestionsProvider(_selected.id)
            .overrideWith((ref) async => [first, second]),
      ]);
      addTearDown(container.dispose);
      container.read(selectedAnimalProvider.notifier).select(_selected);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: DiscoverScreen()),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Estrela'), findsOneWidget);

      await _tapAction(tester, 'Passar');

      expect(find.text('Estrela'), findsNothing);
      expect(find.text('Sultão'), findsOneWidget);
    });
  });
}

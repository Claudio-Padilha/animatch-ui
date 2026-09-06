import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/core/router/app_router.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/herd/domain/animal_enums.dart';
import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/herd/providers/herd_provider.dart';
import 'package:animatch/features/herd/providers/selected_animal_provider.dart';
import 'package:animatch/features/herd/ui/herd_screen.dart';
import 'package:animatch/shared/widgets/unverified_profile_prompt.dart';

import '../helpers/fakes.dart';

const _verifiedBreeder = Breeder(
  id: 'b1',
  name: 'Fazenda X',
  email: 'x@example.com',
  status: BreederStatus.active,
);

HerdAnimal _animal(String id, {bool available = true}) => HerdAnimal(
      id: id,
      name: 'Animal $id',
      breed: 'Nelore',
      sex: 'Macho',
      species: AnimalSpecies.cattle,
      available: available,
    );

Future<ProviderContainer> _pumpHerdScreen(
  WidgetTester tester, {
  Breeder? breeder = _verifiedBreeder,
  FakeHerdRepository? herdRepository,
}) async {
  tester.view.physicalSize = const Size(480, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    // Disable Riverpod 3.x's default AsyncNotifier retry-with-backoff so a
    // failing herdProvider settles into AsyncError on the first attempt.
    retry: (retryCount, error) => null,
    overrides: [
      authNotifierProvider.overrideWith(() => SeededAuthNotifier(breeder)),
      herdRepositoryProvider
          .overrideWithValue(herdRepository ?? FakeHerdRepository()),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(
    initialLocation: '/herd',
    routes: [
      GoRoute(path: '/herd', builder: (context, state) => const HerdScreen()),
      GoRoute(
        path: AppRoutes.discover,
        builder: (context, state) => const Text('discover-screen'),
      ),
      GoRoute(
        path: AppRoutes.addAnimal,
        builder: (context, state) => const Text('add-animal-screen'),
      ),
      GoRoute(
        path: AppRoutes.myAnimalDetail,
        builder: (context, state) =>
            Text('animal-detail:${state.pathParameters['animalId']}'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  await tester.pump();
  return container;
}

void main() {
  group('HerdScreen', () {
    testWidgets('unverified breeder sees UnverifiedProfilePrompt, not the '
        'herd list', (tester) async {
      await _pumpHerdScreen(
        tester,
        breeder: const Breeder(id: 'b1', name: 'X', email: 'x@x.com'),
        herdRepository: FakeHerdRepository(getAnimalsResult: [_animal('a1')]),
      );

      expect(find.byType(UnverifiedProfilePrompt), findsOneWidget);
      expect(find.text('Animal a1'), findsNothing);
    });

    testWidgets('loading state', (tester) async {
      tester.view.physicalSize = const Size(480, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(overrides: [
        authNotifierProvider
            .overrideWith(() => SeededAuthNotifier(_verifiedBreeder)),
        herdProvider.overrideWith(_NeverLoadingHerdNotifier.new),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: HerdScreen()),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error state with retry button invalidating herdProvider',
        (tester) async {
      final repo = FakeHerdRepository(getAnimalsError: Exception('boom'));
      await _pumpHerdScreen(tester, herdRepository: repo);

      expect(find.text('Erro ao carregar animais'), findsOneWidget);
      expect(repo.getAnimalsCalls, 1);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();

      expect(repo.getAnimalsCalls, 2);
    });

    testWidgets('empty state shows the add-animal CTA', (tester) async {
      await _pumpHerdScreen(
        tester,
        herdRepository: FakeHerdRepository(getAnimalsResult: const []),
      );

      expect(find.text('Nenhum animal cadastrado'), findsOneWidget);

      await tester.tap(find.text('Adicionar animal'));
      await tester.pumpAndSettle();

      expect(find.text('add-animal-screen'), findsOneWidget);
    });

    testWidgets('populated: renders a card per animal', (tester) async {
      await _pumpHerdScreen(
        tester,
        herdRepository: FakeHerdRepository(
          getAnimalsResult: [_animal('a1'), _animal('a2')],
        ),
      );

      expect(find.text('Animal a1'), findsOneWidget);
      expect(find.text('Animal a2'), findsOneWidget);
    });

    testWidgets(
        'selecting an animal updates selectedAnimalProvider and navigates '
        'to Discover', (tester) async {
      final container = await _pumpHerdScreen(
        tester,
        herdRepository: FakeHerdRepository(getAnimalsResult: [_animal('a1')]),
      );

      await tester.tap(find.text('Selecionar'));
      await tester.pumpAndSettle();

      expect(container.read(selectedAnimalProvider)?.id, 'a1');
      expect(find.text('discover-screen'), findsOneWidget);
    });

    testWidgets('tapping an animal card navigates to myAnimalDetailPath',
        (tester) async {
      await _pumpHerdScreen(
        tester,
        herdRepository: FakeHerdRepository(getAnimalsResult: [_animal('a1')]),
      );

      await tester.tap(find.text('Animal a1'));
      await tester.pumpAndSettle();

      expect(find.text('animal-detail:a1'), findsOneWidget);
    });

    testWidgets('quota bar: fraction and copy below the limit', (tester) async {
      await _pumpHerdScreen(
        tester,
        herdRepository: FakeHerdRepository(
          getAnimalsResult: [_animal('a1'), _animal('a2')],
        ),
      );

      expect(find.text('2 / 5 animais'), findsOneWidget);
      expect(
        find.text('Upgrade para adicionar animais ilimitados →'),
        findsOneWidget,
      );
    });

    testWidgets('quota bar: "limite atingido" copy at count >= 5',
        (tester) async {
      await _pumpHerdScreen(
        tester,
        herdRepository: FakeHerdRepository(
          getAnimalsResult:
              List.generate(5, (i) => _animal('a$i')),
        ),
      );

      expect(find.text('5 / 5 animais'), findsOneWidget);
      expect(
        find.text('Limite atingido — faça upgrade para adicionar mais animais'),
        findsOneWidget,
      );
    });

    testWidgets('_AvailabilityChip label for available vs unavailable',
        (tester) async {
      await _pumpHerdScreen(
        tester,
        herdRepository: FakeHerdRepository(getAnimalsResult: [
          _animal('a1'),
          _animal('a2', available: false),
        ]),
      );

      expect(find.text('Disponível'), findsOneWidget);
      expect(find.text('Indisponível'), findsOneWidget);
    });
  });
}

class _NeverLoadingHerdNotifier extends HerdNotifier {
  @override
  Future<List<HerdAnimal>> build() => Completer<List<HerdAnimal>>().future;
}

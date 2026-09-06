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
import 'package:animatch/features/herd/ui/my_animal_detail_screen.dart';

import '../helpers/fakes.dart';

const _breeder = Breeder(id: 'b1', name: 'Fazenda X', email: 'x@example.com');

final _animal = HerdAnimal(
  id: 'a1',
  name: 'Imperador',
  breed: 'Nelore',
  sex: 'Macho',
  species: AnimalSpecies.cattle,
  available: true,
);

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  FakeHerdRepository? herdRepository,
}) async {
  tester.view.physicalSize = const Size(480, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
      herdRepositoryProvider.overrideWithValue(
        herdRepository ?? FakeHerdRepository(getAnimalsResult: [_animal]),
      ),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const MyAnimalDetailScreen(animalId: 'a1'),
    ),
    GoRoute(
      path: AppRoutes.editAnimal,
      builder: (context, state) =>
          Text('edit-animal:${state.pathParameters['animalId']}'),
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
  return container;
}

void main() {
  group('MyAnimalDetailScreen', () {
    testWidgets('loading state (delegated to herdProvider)', (tester) async {
      tester.view.physicalSize = const Size(480, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(overrides: [
        authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
        herdProvider.overrideWith(_NeverLoadingHerdNotifier.new),
      ]);
      addTearDown(container.dispose);

      // AppBottomNav (in MyAnimalDetailScreen's bottomNavigationBar) reads
      // GoRouterState.of(context), so this needs a real GoRouter — a bare
      // MaterialApp(home: ...) throws when it tries to build.
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const MyAnimalDetailScreen(animalId: 'a1'),
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

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'error state via ref.invalidate(herdProvider) retry — also covers '
        'the id-not-in-list edge case: firstWhere throwing inside '
        'whenData() is caught (turned into AsyncError by Riverpod itself), '
        'not an uncaught crash', (tester) async {
      final repo = FakeHerdRepository(getAnimalsResult: const []);
      await _pumpScreen(tester, herdRepository: repo);

      expect(find.text('Erro ao carregar animal'), findsOneWidget);
      expect(repo.getAnimalsCalls, 1);

      await tester.tap(find.text('Tentar novamente'));
      await tester.pump();
      await tester.pump();

      expect(repo.getAnimalsCalls, 2);
    });

    testWidgets('data state: renders the animal, edit button navigates to '
        'editAnimalPath', (tester) async {
      await _pumpScreen(tester);

      expect(find.text('Imperador'), findsOneWidget);

      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('edit-animal:a1'), findsOneWidget);
    });

    testWidgets(
        'conditional sections only render when present/non-empty',
        (tester) async {
      // Bare animal: no description, no location, no genetic indices.
      await _pumpScreen(tester);

      expect(find.text('DESCRIÇÃO'), findsNothing);
      expect(find.text('LOCALIZAÇÃO'), findsNothing);
      expect(find.text('DEP / ÍNDICES GENÉTICOS'), findsNothing);

      final full = _animal.copyWith(
        description: 'Touro premiado',
        city: 'Uberaba',
        state: 'MG',
        location: 'Uberaba, MG',
        geneticIndices: const GeneticIndices(birthWeight: 30.0),
      );
      await _pumpScreen(
        tester,
        herdRepository: FakeHerdRepository(getAnimalsResult: [full]),
      );

      expect(find.text('DESCRIÇÃO'), findsOneWidget);
      expect(find.text('LOCALIZAÇÃO'), findsOneWidget);
      expect(find.text('DEP / ÍNDICES GENÉTICOS'), findsOneWidget);
    });
  });
}

class _NeverLoadingHerdNotifier extends HerdNotifier {
  @override
  Future<List<HerdAnimal>> build() => Completer<List<HerdAnimal>>().future;
}

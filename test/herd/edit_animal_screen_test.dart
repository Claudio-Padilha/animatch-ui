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
import 'package:animatch/features/herd/ui/edit_animal_screen.dart';
import 'package:animatch/features/locations/providers/locations_provider.dart';
import 'package:animatch/features/profile/providers/profile_provider.dart';

import '../helpers/fakes.dart';

const _breeder = Breeder(id: 'b1', name: 'Fazenda X', email: 'x@example.com');

final _animal = HerdAnimal(
  id: 'a1',
  name: 'Imperador',
  breed: 'Nelore',
  sex: 'Macho',
  species: AnimalSpecies.cattle,
  available: true,
  propertyName: 'Fazenda Boa Vista',
  city: 'Uberaba',
  state: 'MG',
  zipCode: '12345000',
);

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  FakeHerdRepository? herdRepository,
  HerdAnimal? animal,
}) async {
  tester.view.physicalSize = const Size(430, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repo = herdRepository ??
      FakeHerdRepository(getAnimalsResult: [animal ?? _animal]);

  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
      herdRepositoryProvider.overrideWithValue(repo),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      municipalitiesProvider.overrideWith((ref) async => throw Exception('offline')),
    ],
  );
  addTearDown(container.dispose);

  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => const Text('base-screen')),
    GoRoute(
      path: '/edit',
      builder: (context, state) => const EditAnimalScreen(animalId: 'a1'),
    ),
    GoRoute(
      path: AppRoutes.herd,
      builder: (context, state) => const Text('herd-screen'),
    ),
  ]);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  router.push('/edit');
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('EditAnimalScreen', () {
    testWidgets('loading state', (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(overrides: [
        authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
        animalDetailProvider('a1').overrideWith(
          (ref) => Completer<HerdAnimal>().future,
        ),
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EditAnimalScreen(animalId: 'a1'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error state', (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
          animalDetailProvider('a1')
              .overrideWith((ref) async => throw Exception('boom')),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EditAnimalScreen(animalId: 'a1'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Erro ao carregar animal'), findsOneWidget);
    });

    testWidgets('form pre-populated from the loaded HerdAnimal', (tester) async {
      await _pumpScreen(tester);

      final nameField =
          tester.widget<TextFormField>(find.byType(TextFormField).first);
      expect(nameField.controller!.text, 'Imperador');
      expect(
        tester
            .widget<TextFormField>(
                find.widgetWithText(TextFormField, 'Nome da propriedade'))
            .controller!
            .text,
        'Fazenda Boa Vista',
      );
      expect(find.text(AnimalBreed.nelore.label), findsOneWidget);
      expect(find.text('Macho'), findsOneWidget);
    });

    testWidgets('save: builds the expected payload shape', (tester) async {
      final repo = FakeHerdRepository(
        getAnimalsResult: [_animal],
        updateAnimalResult: _animal,
      );
      await _pumpScreen(tester, herdRepository: repo);

      await tester.enterText(find.byType(TextFormField).first, 'Novo Nome');
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      await tester.pump();

      final (id, payload) = repo.updateAnimalCalls.single;
      expect(id, 'a1');
      expect(payload['name'], 'Novo Nome');
      expect(payload['breed'], AnimalBreed.nelore.apiValue);
      expect(payload['sex'], 'male');
    });

    testWidgets(
        'delete flow: confirm dialog -> deleteAnimalProvider -> navigates '
        'to herd on success', (tester) async {
      final repo = FakeHerdRepository(getAnimalsResult: [_animal]);
      await _pumpScreen(tester, herdRepository: repo);

      await tester.tap(find.text('Apagar animal'));
      await tester.pumpAndSettle();
      expect(find.text('Apagar animal'), findsWidgets); // dialog title too

      await tester.tap(find.text('Apagar').last);
      await tester.pumpAndSettle();

      expect(repo.deleteAnimalCalls, ['a1']);
      expect(find.text('herd-screen'), findsOneWidget);
    });

    testWidgets(
        'delete flow: on AsyncError, shows the error SnackBar and stays on '
        'screen', (tester) async {
      final repo = FakeHerdRepository(
        getAnimalsResult: [_animal],
        deleteAnimalError: Exception('boom'),
      );
      await _pumpScreen(tester, herdRepository: repo);

      await tester.tap(find.text('Apagar animal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apagar').last);
      await tester.pump();
      await tester.pump();

      expect(find.text('Erro ao apagar. Tente novamente.'), findsOneWidget);
      expect(find.text('herd-screen'), findsNothing);
    });

    testWidgets(
        'toggle flow: confirm dialog -> _available flips locally, button '
        'label/icon swap on success', (tester) async {
      final repo = FakeHerdRepository(
        getAnimalsResult: [_animal],
        updateAnimalResult: _animal.copyWith(available: false),
      );
      await _pumpScreen(tester, herdRepository: repo);

      expect(find.text('Pausar perfil'), findsOneWidget);

      await tester.tap(find.text('Pausar perfil'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pausar').last);
      await tester.pumpAndSettle();

      final (id, payload) = repo.updateAnimalCalls.single;
      expect(id, 'a1');
      expect(payload, {'status': 'paused'});
      expect(find.text('Ativar perfil'), findsOneWidget);
    });
  });
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/herd/domain/animal_enums.dart';
import 'package:animatch/core/services/cloudinary_uploader.dart';
import 'package:animatch/features/herd/providers/herd_provider.dart';
import 'package:animatch/features/herd/ui/add_animal_screen.dart';
import 'package:animatch/features/locations/providers/locations_provider.dart';
import 'package:animatch/features/profile/providers/profile_provider.dart';

import '../helpers/fakes.dart';

const _breeder = Breeder(id: 'b1', name: 'Fazenda X', email: 'x@example.com');

HerdAnimal _resultAnimal() => HerdAnimal(
      id: 'new1',
      name: 'Imperador',
      breed: 'Nelore',
      sex: 'Macho',
      species: AnimalSpecies.cattle,
      available: true,
    );

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  FakeHerdRepository? herdRepository,
  CloudinaryUploader? cloudinaryUploader,
}) async {
  tester.view.physicalSize = const Size(430, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    retry: (retryCount, error) => null,
    overrides: [
      authNotifierProvider.overrideWith(() => SeededAuthNotifier(_breeder)),
      herdRepositoryProvider
          .overrideWithValue(herdRepository ?? FakeHerdRepository()),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
      municipalitiesProvider.overrideWith((ref) async => throw Exception('offline')),
      cloudinaryUploaderProvider.overrideWithValue(
        cloudinaryUploader ?? FakeCloudinaryUploader(),
      ),
    ],
  );
  addTearDown(container.dispose);

  // A base route so context.pop() (used on successful submit) has
  // something to pop back to.
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (context, state) => const Text('herd-screen')),
    GoRoute(path: '/add', builder: (context, state) => const AddAnimalScreen()),
  ]);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  router.push('/add');
  await tester.pumpAndSettle();
  return container;
}

/// Opens the Nth `DropdownButtonFormField<String>` and taps [optionLabel]
/// in the resulting menu.
Future<void> _selectDropdown(
  WidgetTester tester,
  int index,
  String optionLabel,
) async {
  final dropdowns = find.byType(DropdownButtonFormField<String>);
  await tester.tap(dropdowns.at(index));
  await tester.pumpAndSettle();
  await tester.tap(find.text(optionLabel).last);
  await tester.pumpAndSettle();
}

void main() {
  group('AddAnimalScreen', () {
    testWidgets(
        'form validation: name, breed, sex required — blocks submit with '
        'visible error text', (tester) async {
      final repo = FakeHerdRepository(addAnimalResult: _resultAnimal());
      await _pumpScreen(tester, herdRepository: repo);

      await tester.tap(find.text('Salvar animal'));
      await tester.pump();

      expect(find.text('Campo obrigatório'), findsWidgets);
      expect(repo.addAnimalPayloads, isEmpty);
    });

    testWidgets('species change resets breed/sex selection', (tester) async {
      await _pumpScreen(tester);

      // Select a breed and sex under the default species (Bovino).
      await _selectDropdown(tester, 1, AnimalBreed.nelore.label);
      await _selectDropdown(tester, 2, 'Macho');
      expect(find.text(AnimalBreed.nelore.label), findsOneWidget);

      // Switching species clears both.
      await _selectDropdown(tester, 0, AnimalSpecies.horse.label);

      expect(find.text(AnimalBreed.nelore.label), findsNothing);
      expect(find.text('Macho'), findsNothing);
      // Both dropdowns fall back to their unselected hint.
      expect(find.text('Selecionar'), findsNWidgets(2));
    });

    testWidgets(
        'successful submit calls addAnimalProvider.notifier.addAnimal with '
        'the expected payload', (tester) async {
      final repo = FakeHerdRepository(addAnimalResult: _resultAnimal());
      await _pumpScreen(tester, herdRepository: repo);

      await tester.enterText(find.byType(TextFormField).first, 'Imperador');
      await _selectDropdown(tester, 1, AnimalBreed.nelore.label);
      await _selectDropdown(tester, 2, 'Macho');

      // Property name field.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome da propriedade'),
        'Fazenda Boa Vista',
      );
      // Free-text city/state fallback (municipalitiesProvider errors).
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cidade'),
        'Uberaba',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Estado'),
        'MG',
      );

      await tester.tap(find.text('Salvar animal'));
      await tester.pump();
      await tester.pump();

      final payload = repo.addAnimalPayloads.single;
      expect(payload['name'], 'Imperador');
      expect(payload['breed'], AnimalBreed.nelore.apiValue);
      expect(payload['sex'], 'male');
      expect(payload['address'], {
        'directions': 'Fazenda Boa Vista',
        'zipCode': '',
        'city': 'Uberaba',
        'state': 'MG',
      });
    });

    testWidgets('error SnackBar shown when addAnimalProvider resolves to '
        'AsyncError after submit', (tester) async {
      final repo = FakeHerdRepository(addAnimalError: Exception('boom'));
      await _pumpScreen(tester, herdRepository: repo);

      await tester.enterText(find.byType(TextFormField).first, 'Imperador');
      await _selectDropdown(tester, 1, AnimalBreed.nelore.label);
      await _selectDropdown(tester, 2, 'Macho');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome da propriedade'),
        'Fazenda Boa Vista',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cidade'),
        'Uberaba',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Estado'),
        'MG',
      );

      await tester.tap(find.text('Salvar animal'));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Erro ao salvar animal'), findsOneWidget);
    });

    testWidgets('photo picker: tapping add opens the source-chooser bottom '
        'sheet', (tester) async {
      await _pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Tirar foto'), findsOneWidget);
      expect(find.text('Escolher da galeria'), findsOneWidget);
    });

    testWidgets(
        'photo picker: choosing a source uploads via CloudinaryUploader and '
        'adds the returned URL as a new photo tile', (tester) async {
      final uploader =
          FakeCloudinaryUploader(result: 'https://cdn.example.com/a.jpg');
      await _pumpScreen(tester, cloudinaryUploader: uploader);

      await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escolher da galeria'));
      await tester.pumpAndSettle();

      expect(uploader.pickAndUploadCalls, 1);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets(
        'photo picker: the add tile disappears once 3 photos have been '
        'uploaded (max-3 enforcement)', (tester) async {
      final uploader =
          FakeCloudinaryUploader(result: 'https://cdn.example.com/a.jpg');
      await _pumpScreen(tester, cloudinaryUploader: uploader);

      for (var i = 0; i < 3; i++) {
        expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
        await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Escolher da galeria'));
        await tester.pumpAndSettle();
      }

      expect(uploader.pickAndUploadCalls, 3);
      expect(find.byType(CachedNetworkImage), findsNWidgets(3));
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);
    });
  });
}

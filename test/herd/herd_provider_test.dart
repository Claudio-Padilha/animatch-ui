import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';
import 'package:animatch/features/herd/domain/animal_enums.dart';
import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/herd/providers/herd_provider.dart';
import 'package:animatch/features/herd/providers/selected_animal_provider.dart';
import 'package:animatch/features/profile/providers/profile_provider.dart';

import '../helpers/fakes.dart';

const _breeder = Breeder(id: 'b1', name: 'Fazenda X', email: 'x@example.com');

HerdAnimal _animal(String id, {bool available = true}) => HerdAnimal(
      id: id,
      name: 'Animal $id',
      breed: 'Nelore',
      sex: 'Macho',
      species: AnimalSpecies.cattle,
      available: available,
    );

ProviderContainer _buildContainer({
  Breeder? breeder = _breeder,
  FakeHerdRepository? herdRepository,
  FakeProfileRepository? profileRepository,
}) {
  final container = ProviderContainer(overrides: [
    authNotifierProvider.overrideWith(() => SeededAuthNotifier(breeder)),
    herdRepositoryProvider
        .overrideWithValue(herdRepository ?? FakeHerdRepository()),
    profileRepositoryProvider
        .overrideWithValue(profileRepository ?? FakeProfileRepository()),
  ]);
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('HerdNotifier.build', () {
    test('returns an empty list when logged out', () async {
      final container = _buildContainer(breeder: null);
      final animals = await container.read(herdProvider.future);
      expect(animals, isEmpty);
    });

    test('fetches via the repository when logged in (owner derived from token)',
        () async {
      final repo = FakeHerdRepository(getAnimalsResult: [_animal('a1')]);
      final container = _buildContainer(herdRepository: repo);

      final animals = await container.read(herdProvider.future);

      expect(animals, hasLength(1));
      expect(repo.getAnimalsCalls, 1);
    });
  });

  group('HerdNotifier.refresh', () {
    test('is a no-op when logged out', () async {
      final repo = FakeHerdRepository(getAnimalsResult: [_animal('a1')]);
      final container = _buildContainer(breeder: null, herdRepository: repo);
      await container.read(herdProvider.future);

      await container.read(herdProvider.notifier).refresh();

      expect(repo.getAnimalsCalls, 0);
      expect(container.read(herdProvider).value, isEmpty);
    });

    test('sets loading then resolves to fresh data on success', () async {
      final repo = FakeHerdRepository(getAnimalsResult: [_animal('a1')]);
      final container = _buildContainer(herdRepository: repo);
      await container.read(herdProvider.future);

      final refreshFuture = container.read(herdProvider.notifier).refresh();
      expect(container.read(herdProvider), isA<AsyncLoading>());
      await refreshFuture;

      expect(container.read(herdProvider).value, hasLength(1));
      expect(repo.getAnimalsCalls, 2);
    });

    test('resolves to AsyncError on failure', () async {
      final repo = FakeHerdRepository(getAnimalsError: Exception('boom'));
      final container = _buildContainer(herdRepository: repo);

      await container.read(herdProvider.notifier).refresh();

      expect(container.read(herdProvider), isA<AsyncError>());
    });
  });

  group('HerdNotifier.remove', () {
    test('filters the given id out of AsyncData', () async {
      final repo =
          FakeHerdRepository(getAnimalsResult: [_animal('a1'), _animal('a2')]);
      final container = _buildContainer(herdRepository: repo);
      await container.read(herdProvider.future);

      container.read(herdProvider.notifier).remove('a1');

      final remaining = container.read(herdProvider).value!;
      expect(remaining.map((a) => a.id), ['a2']);
    });

    test('no-ops when state is not AsyncData (still loading)', () async {
      final container = _buildContainer(herdRepository: FakeHerdRepository());
      // Don't await — state is AsyncLoading while the future is in flight.
      final pending = container.read(herdProvider.future);

      container.read(herdProvider.notifier).remove('a1');

      expect(await pending, isEmpty);
    });
  });

  group('HerdNotifier.updateOne', () {
    test('replaces the matching-id entry in place, preserves others',
        () async {
      final repo =
          FakeHerdRepository(getAnimalsResult: [_animal('a1'), _animal('a2')]);
      final container = _buildContainer(herdRepository: repo);
      await container.read(herdProvider.future);

      container
          .read(herdProvider.notifier)
          .updateOne(_animal('a1', available: false));

      final animals = container.read(herdProvider).value!;
      expect(animals.firstWhere((a) => a.id == 'a1').available, isFalse);
      expect(animals.firstWhere((a) => a.id == 'a2').available, isTrue);
    });
  });

  group('AddAnimalNotifier.addAnimal', () {
    Map<String, dynamic> baseArgsPayload(FakeHerdRepository repo) {
      return repo.addAnimalPayloads.single;
    }

    test('builds the expected payload shape', () async {
      final repo = FakeHerdRepository(addAnimalResult: _animal('new'));
      final container = _buildContainer(herdRepository: repo);

      await container.read(addAnimalProvider.notifier).addAnimal(
            name: 'Trovão',
            species: AnimalSpecies.cattle,
            breed: AnimalBreed.nelore,
            sexLabel: 'Macho',
            propertyName: 'Fazenda Boa Vista',
            zipCode: '12345000',
            city: 'Uberaba',
            state: 'mg',
            description: 'Touro premiado',
            age: 3,
            registrationNumber: 'REG123',
            geneticIndices: {'birth_weight': 32.0, 'weight_18m': 0.0},
            imageUrls: ['https://img/1.png'],
          );

      final payload = baseArgsPayload(repo);
      // breederId is no longer sent — the backend derives the owner from the
      // auth token.
      expect(payload.containsKey('breederId'), isFalse);
      expect(payload['name'], 'Trovão');
      expect(payload['species'], 'cattle');
      expect(payload['breed'], 'nelore');
      expect(payload['sex'], 'male');
      expect(payload['status'], 'active');
      expect(payload['address'], {
        'directions': 'Fazenda Boa Vista',
        'zipCode': '12345000',
        'city': 'Uberaba',
        'state': 'MG',
      });
      expect(payload['description'], 'Touro premiado');
      expect(payload['age'], 3);
      expect(payload['registrationNumber'], 'REG123');
      expect(payload['photoUrls'], ['https://img/1.png']);
      // geneticIndices is sent all-4-keys-or-not-at-all; a 0 collapses to null
      // (the backend rejects a partial object and rejects 0).
      expect(payload['geneticIndices'], {
        'birth_weight': 32.0,
        'milk_restriction_weight': null,
        'weight_18m': null,
        'fertility_index': null,
      });
    });

    test('available: false maps to status "paused", not "inactive"', () async {
      final repo = FakeHerdRepository(addAnimalResult: _animal('new'));
      final container = _buildContainer(herdRepository: repo);

      await container.read(addAnimalProvider.notifier).addAnimal(
            name: 'Trovão',
            species: AnimalSpecies.cattle,
            breed: AnimalBreed.nelore,
            sexLabel: 'Macho',
            propertyName: 'Fazenda Boa Vista',
            zipCode: '12345000',
            city: 'Uberaba',
            state: 'mg',
            available: false,
          );

      expect(repo.addAnimalPayloads.single['status'], 'paused');
    });

    test('omits optional fields entirely when not provided', () async {
      final repo = FakeHerdRepository(addAnimalResult: _animal('new'));
      final container = _buildContainer(herdRepository: repo);

      await container.read(addAnimalProvider.notifier).addAnimal(
            name: 'Trovão',
            species: AnimalSpecies.cattle,
            breed: AnimalBreed.nelore,
            sexLabel: 'Macho',
            propertyName: 'Fazenda Boa Vista',
            zipCode: '12345000',
            city: 'Uberaba',
            state: 'mg',
          );

      final payload = baseArgsPayload(repo);
      expect(payload.containsKey('description'), isFalse);
      expect(payload.containsKey('age'), isFalse);
      expect(payload.containsKey('registrationNumber'), isFalse);
      expect(payload.containsKey('photoUrls'), isFalse);
      expect(payload.containsKey('geneticIndices'), isFalse);
    });

    test('on success: refreshes herdProvider and invalidates '
        'breederStatisticsProvider', () async {
      final herdRepo = FakeHerdRepository(
        getAnimalsResult: [_animal('new')],
        addAnimalResult: _animal('new'),
      );
      final profileRepo = FakeProfileRepository();
      final container = _buildContainer(
        herdRepository: herdRepo,
        profileRepository: profileRepo,
      );
      // Establish an initial herd fetch + a listened statistics provider so
      // invalidation triggers an eager rebuild we can observe.
      await container.read(herdProvider.future);
      container.listen(breederStatisticsProvider, (_, _) {});
      await container.read(breederStatisticsProvider.future);
      expect(herdRepo.getAnimalsCalls, 1);
      expect(profileRepo.getStatisticsCalls, 1);

      await container.read(addAnimalProvider.notifier).addAnimal(
            name: 'Trovão',
            species: AnimalSpecies.cattle,
            breed: AnimalBreed.nelore,
            sexLabel: 'Macho',
            propertyName: 'Fazenda Boa Vista',
            zipCode: '12345000',
            city: 'Uberaba',
            state: 'MG',
          );

      expect(herdRepo.getAnimalsCalls, 2);
      await container.pump();
      expect(profileRepo.getStatisticsCalls, 2);
      expect(container.read(addAnimalProvider), isA<AsyncData>());
    });

    test('on failure: state is AsyncError, no refresh/invalidate side '
        'effects fire', () async {
      final herdRepo = FakeHerdRepository(
        getAnimalsResult: [],
        addAnimalError: Exception('rejected'),
      );
      final profileRepo = FakeProfileRepository();
      final container = _buildContainer(
        herdRepository: herdRepo,
        profileRepository: profileRepo,
      );
      await container.read(herdProvider.future);
      expect(herdRepo.getAnimalsCalls, 1);

      await container.read(addAnimalProvider.notifier).addAnimal(
            name: 'Trovão',
            species: AnimalSpecies.cattle,
            breed: AnimalBreed.nelore,
            sexLabel: 'Macho',
            propertyName: 'Fazenda Boa Vista',
            zipCode: '12345000',
            city: 'Uberaba',
            state: 'MG',
          );

      expect(container.read(addAnimalProvider), isA<AsyncError>());
      // refresh() was not called again — still just the initial build fetch.
      expect(herdRepo.getAnimalsCalls, 1);
      expect(profileRepo.getStatisticsCalls, 0);
    });
  });

  group('UpdateAnimalNotifier.updateAnimal', () {
    test('builds the expected payload shape (registrationNumber key — K-1 '
        'fixed)', () async {
      final repo = FakeHerdRepository(updateAnimalResult: _animal('a1'));
      final container = _buildContainer(
        herdRepository: repo,
        profileRepository: FakeProfileRepository(),
      );

      await container.read(updateAnimalProvider.notifier).updateAnimal(
            id: 'a1',
            name: 'Trovão',
            species: AnimalSpecies.cattle,
            breed: AnimalBreed.nelore,
            sexLabel: 'Macho',
            city: 'Uberaba',
            state: 'mg',
            zipCode: '12345000',
            propertyName: 'Fazenda Boa Vista',
            registrationNumber: 'REG123',
          );

      final (id, payload) = repo.updateAnimalCalls.single;
      expect(id, 'a1');
      // K-1 resolved: the backend's canonical key is camelCase
      // `registrationNumber` on both POST and PATCH (confirmed against the
      // `CreateAnimalBody` DTO). `updateAnimal` previously sent snake_case,
      // which Fastify silently dropped — the update "succeeded" but the
      // registration number was never persisted.
      expect(payload['registrationNumber'], 'REG123');
      expect(payload.containsKey('registration_number'), isFalse);
      // status enum is 'active' | 'paused' (never 'inactive').
      expect(payload['status'], 'active');
    });

    test('on success: calls herdProvider.updateOne (not a full refresh)',
        () async {
      final repo = FakeHerdRepository(
        getAnimalsResult: [_animal('a1')],
        updateAnimalResult: _animal('a1', available: false),
      );
      final container = _buildContainer(herdRepository: repo);
      await container.read(herdProvider.future);
      expect(repo.getAnimalsCalls, 1);

      await container.read(updateAnimalProvider.notifier).updateAnimal(
            id: 'a1',
            name: 'Trovão',
            species: AnimalSpecies.cattle,
            breed: AnimalBreed.nelore,
            sexLabel: 'Macho',
            city: 'Uberaba',
            state: 'MG',
            zipCode: '12345000',
            propertyName: 'Fazenda Boa Vista',
            available: false,
          );

      // updateOne, not refresh(): getAnimals was never called a second time.
      expect(repo.getAnimalsCalls, 1);
      expect(
        container.read(herdProvider).value!.single.available,
        isFalse,
      );
    });

    test('on failure: state is AsyncError, herdProvider is left untouched',
        () async {
      final repo = FakeHerdRepository(
        getAnimalsResult: [_animal('a1')],
        updateAnimalError: Exception('rejected'),
      );
      final container = _buildContainer(herdRepository: repo);
      await container.read(herdProvider.future);

      await container.read(updateAnimalProvider.notifier).updateAnimal(
            id: 'a1',
            name: 'Trovão',
            species: AnimalSpecies.cattle,
            breed: AnimalBreed.nelore,
            sexLabel: 'Macho',
            city: 'Uberaba',
            state: 'MG',
            zipCode: '12345000',
            propertyName: 'Fazenda Boa Vista',
          );

      expect(container.read(updateAnimalProvider), isA<AsyncError>());
      // Still the pre-update animal — updateOne never fired.
      expect(container.read(herdProvider).value!.single.available, isTrue);
    });
  });

  group('ToggleAnimalNotifier.toggle', () {
    test('flips active -> paused and vice versa, updates herd + invalidates '
        'statistics on success', () async {
      final herdRepo = FakeHerdRepository(
        getAnimalsResult: [_animal('a1')],
        updateAnimalResult: _animal('a1', available: false),
      );
      final profileRepo = FakeProfileRepository();
      final container = _buildContainer(
        herdRepository: herdRepo,
        profileRepository: profileRepo,
      );
      await container.read(herdProvider.future);
      container.listen(breederStatisticsProvider, (_, _) {});
      await container.read(breederStatisticsProvider.future);
      expect(profileRepo.getStatisticsCalls, 1);

      await container
          .read(toggleAnimalProvider.notifier)
          .toggle('a1', currentlyActive: true);

      final (id, payload) = herdRepo.updateAnimalCalls.single;
      expect(id, 'a1');
      expect(payload, {'status': 'paused'});
      expect(container.read(herdProvider).value!.single.available, isFalse);
      await container.pump();
      expect(profileRepo.getStatisticsCalls, 2);
    });

    test('currentlyActive: false sends status: active', () async {
      final herdRepo = FakeHerdRepository(
        getAnimalsResult: [_animal('a1', available: false)],
        updateAnimalResult: _animal('a1'),
      );
      final container = _buildContainer(herdRepository: herdRepo);
      await container.read(herdProvider.future);

      await container
          .read(toggleAnimalProvider.notifier)
          .toggle('a1', currentlyActive: false);

      final (_, payload) = herdRepo.updateAnimalCalls.single;
      expect(payload, {'status': 'active'});
    });

    test('on failure: state is AsyncError, no herd update or statistics '
        'invalidation fires', () async {
      final herdRepo = FakeHerdRepository(
        getAnimalsResult: [_animal('a1')],
        updateAnimalError: Exception('boom'),
      );
      final profileRepo = FakeProfileRepository();
      final container = _buildContainer(
        herdRepository: herdRepo,
        profileRepository: profileRepo,
      );
      await container.read(herdProvider.future);

      await container
          .read(toggleAnimalProvider.notifier)
          .toggle('a1', currentlyActive: true);

      expect(container.read(toggleAnimalProvider), isA<AsyncError>());
      expect(container.read(herdProvider).value!.single.available, isTrue);
      expect(profileRepo.getStatisticsCalls, 0);
    });
  });

  group('DeleteAnimalNotifier.deleteAnimal', () {
    test('on success: removes from herdProvider and invalidates statistics',
        () async {
      final herdRepo =
          FakeHerdRepository(getAnimalsResult: [_animal('a1'), _animal('a2')]);
      final profileRepo = FakeProfileRepository();
      final container = _buildContainer(
        herdRepository: herdRepo,
        profileRepository: profileRepo,
      );
      await container.read(herdProvider.future);
      container.listen(breederStatisticsProvider, (_, _) {});
      await container.read(breederStatisticsProvider.future);
      expect(profileRepo.getStatisticsCalls, 1);

      await container.read(deleteAnimalProvider.notifier).deleteAnimal('a1');

      expect(herdRepo.deleteAnimalCalls, ['a1']);
      expect(container.read(herdProvider).value!.map((a) => a.id), ['a2']);
      await container.pump();
      expect(profileRepo.getStatisticsCalls, 2);
    });

    test('on failure: does not remove from herdProvider or invalidate '
        'statistics (no ghost removal)', () async {
      final herdRepo = FakeHerdRepository(
        getAnimalsResult: [_animal('a1')],
        deleteAnimalError: Exception('boom'),
      );
      final profileRepo = FakeProfileRepository();
      final container = _buildContainer(
        herdRepository: herdRepo,
        profileRepository: profileRepo,
      );
      await container.read(herdProvider.future);

      await container.read(deleteAnimalProvider.notifier).deleteAnimal('a1');

      expect(container.read(deleteAnimalProvider), isA<AsyncError>());
      expect(container.read(herdProvider).value!.map((a) => a.id), ['a1']);
      expect(profileRepo.getStatisticsCalls, 0);
    });
  });

  group('selectedAnimalProvider', () {
    test('defaults to null, select() updates state, select(null) clears it',
        () async {
      final container = _buildContainer();
      expect(container.read(selectedAnimalProvider), isNull);

      final animal = _animal('a1');
      container.read(selectedAnimalProvider.notifier).select(animal);
      expect(container.read(selectedAnimalProvider), animal);

      container.read(selectedAnimalProvider.notifier).select(null);
      expect(container.read(selectedAnimalProvider), isNull);
    });
  });
}

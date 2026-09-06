import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/discover/domain/discover_animal.dart';

void main() {
  group('fromJson', () {
    test('maps breed via AnimalBreed lookup, sex label, and flattens '
        'the address', () {
      final animal = DiscoverAnimal.fromJson({
        'id': 'a1',
        'name': 'Estrela',
        'species': 'cattle',
        'breed': 'nelore',
        'sex': 'female',
        'photoUrls': ['https://img/1.png'],
        'address': {
          'city': 'Uberaba',
          'state': 'MG',
          'directions': 'Fazenda Boa Vista',
        },
        'age': 2,
        'registrationNumber': 'REG1',
        'description': 'Matriz premiada',
        'pendingMatchId': 'pm1',
        'geneticIndices': {'birth_weight': 30.0},
      });

      expect(animal.id, 'a1');
      expect(animal.breed, 'Nelore');
      expect(animal.sex, 'Fêmea');
      expect(animal.photoUrls, ['https://img/1.png']);
      expect(animal.locationCity, 'Uberaba');
      expect(animal.locationState, 'MG');
      expect(animal.locationDirections, 'Fazenda Boa Vista');
      expect(animal.age, 2);
      expect(animal.registrationCode, 'REG1');
      expect(animal.description, 'Matriz premiada');
      expect(animal.pendingMatchId, 'pm1');
      expect(animal.geneticIndices?.birthWeight, 30.0);
    });

    test('falls back to the raw API value when breed is not a known '
        'AnimalBreed enum value, instead of throwing', () {
      final animal = DiscoverAnimal.fromJson({
        'id': 'a1',
        'name': 'Estrela',
        'breed': 'some_future_breed',
        'sex': 'male',
      });

      expect(animal.breed, 'some_future_breed');
    });

    test('male sex maps to Macho', () {
      final animal = DiscoverAnimal.fromJson({
        'id': 'a1',
        'name': 'Trovão',
        'breed': 'nelore',
        'sex': 'male',
      });

      expect(animal.sex, 'Macho');
    });

    test('pendingMatchId and geneticIndices are optional (null when absent)',
        () {
      final animal = DiscoverAnimal.fromJson({
        'id': 'a1',
        'name': 'Trovão',
        'breed': 'nelore',
        'sex': 'male',
      });

      expect(animal.pendingMatchId, isNull);
      expect(animal.geneticIndices, isNull);
      expect(animal.photoUrls, isEmpty);
      expect(animal.locationCity, isEmpty);
      expect(animal.locationState, isEmpty);
    });
  });

  group('locationFull', () {
    test('joins city and state with a comma', () {
      const animal = DiscoverAnimal(
        id: 'a1',
        name: 'Trovão',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Macho',
        photoUrls: [],
        locationCity: 'Uberaba',
        locationState: 'MG',
      );

      expect(animal.locationFull, 'Uberaba, MG');
    });

    test('"state only" when the city is masked, "" when neither is present', () {
      const masked = DiscoverAnimal(
        id: 'a1', name: 'Trovão', species: 'cattle', breed: 'Nelore',
        sex: 'Macho', photoUrls: [], locationCity: '', locationState: 'MG',
      );
      expect(masked.locationFull, 'MG');

      const empty = DiscoverAnimal(
        id: 'a1', name: 'Trovão', species: 'cattle', breed: 'Nelore',
        sex: 'Macho', photoUrls: [], locationCity: '', locationState: '',
      );
      expect(empty.locationFull, '');
    });
  });

  group('ageLabel', () {
    test('singular "1 ano" for age == 1', () {
      const animal = DiscoverAnimal(
        id: 'a1',
        name: 'Trovão',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Macho',
        photoUrls: [],
        locationCity: '',
        locationState: '',
        age: 1,
      );

      expect(animal.ageLabel, '1 ano');
    });

    test('plural "X anos" for age != 1', () {
      const animal = DiscoverAnimal(
        id: 'a1',
        name: 'Trovão',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Macho',
        photoUrls: [],
        locationCity: '',
        locationState: '',
        age: 3,
      );

      expect(animal.ageLabel, '3 anos');
    });

    test('empty string when age is null', () {
      const animal = DiscoverAnimal(
        id: 'a1',
        name: 'Trovão',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Macho',
        photoUrls: [],
        locationCity: '',
        locationState: '',
      );

      expect(animal.ageLabel, '');
    });
  });
}

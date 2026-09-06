import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/discover/domain/discover_animal.dart';
import 'package:animatch/features/herd/domain/animal_enums.dart';
import 'package:animatch/features/herd/domain/herd_animal.dart';
import 'package:animatch/features/matches/domain/match_item.dart';
import 'package:animatch/shared/domain/animal_detail_data.dart';

void main() {
  group('AnimalDetailData.fromDiscoverAnimal', () {
    test('maps every field straight across', () {
      const discover = DiscoverAnimal(
        id: 'a1',
        name: 'Estrela',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Fêmea',
        photoUrls: ['http://img/1.png'],
        locationCity: 'Uberaba',
        locationState: 'MG',
        locationDirections: 'Fazenda Boa Vista',
        age: 3,
        registrationCode: 'REG1',
        description: 'Matriz premiada',
        pendingMatchId: 'pm1',
      );

      final data = AnimalDetailData.fromDiscoverAnimal(discover);

      expect(data.id, 'a1');
      expect(data.name, 'Estrela');
      expect(data.species, 'cattle');
      expect(data.breed, 'Nelore');
      expect(data.sex, 'Fêmea');
      expect(data.photoUrls, ['http://img/1.png']);
      expect(data.locationCity, 'Uberaba');
      expect(data.locationState, 'MG');
      expect(data.locationDirections, 'Fazenda Boa Vista');
      expect(data.age, 3);
      expect(data.description, 'Matriz premiada');
      expect(data.pendingMatchId, 'pm1');
      expect(data.registrationCode, 'REG1');
    });
  });

  group('AnimalDetailData.fromMatchAnimal', () {
    test('_parseCity/_parseState split "City, State" on a single comma', () {
      const match = MatchAnimal(
        id: 'a1',
        name: 'Estrela',
        breed: 'Nelore · Fêmea',
        location: 'Uberaba, MG',
      );

      final data = AnimalDetailData.fromMatchAnimal(match);

      expect(data.locationCity, 'Uberaba');
      expect(data.locationState, 'MG');
    });

    test('no comma: entire string becomes the city, state is empty', () {
      const match = MatchAnimal(
        id: 'a1',
        name: 'Estrela',
        breed: 'Nelore · Fêmea',
        location: 'Uberaba',
      );

      final data = AnimalDetailData.fromMatchAnimal(match);

      expect(data.locationCity, 'Uberaba');
      expect(data.locationState, '');
    });

    test('null location: both city and state are empty', () {
      const match = MatchAnimal(
        id: 'a1',
        name: 'Estrela',
        breed: 'Nelore · Fêmea',
      );

      final data = AnimalDetailData.fromMatchAnimal(match);

      expect(data.locationCity, '');
      expect(data.locationState, '');
    });

    test(
        'regression note: a city name containing a comma silently misparses '
        '(uses .split(",").first / .last, not documented as a known limit — '
        'unlikely in Brazilian municipality names but not validated against '
        'one)', () {
      const match = MatchAnimal(
        id: 'a1',
        name: 'Estrela',
        breed: 'Nelore · Fêmea',
        location: 'Santo Antônio, do Amparo, MG',
      );

      final data = AnimalDetailData.fromMatchAnimal(match);

      // .split(',').first / .last on 3 comma-separated parts drops the
      // middle segment entirely — pinning this so a future fix is
      // deliberate, not an accidental behavior change.
      expect(data.locationCity, 'Santo Antônio');
      expect(data.locationState, 'MG');
    });

    test('id falls back to empty string when null', () {
      const match = MatchAnimal(name: 'Estrela', breed: 'Nelore · Fêmea');

      final data = AnimalDetailData.fromMatchAnimal(match);

      expect(data.id, '');
    });
  });

  group('AnimalDetailData.fromHerdAnimal', () {
    test('maps species via .apiValue and address fields directly', () {
      final herd = HerdAnimal(
        id: 'a1',
        name: 'Imperador',
        breed: 'Nelore',
        sex: 'Macho',
        species: AnimalSpecies.cattle,
        available: true,
        city: 'Uberaba',
        state: 'MG',
        propertyName: 'Fazenda Boa Vista',
      );

      final data = AnimalDetailData.fromHerdAnimal(herd);

      expect(data.id, 'a1');
      expect(data.name, 'Imperador');
      expect(data.breed, 'Nelore');
      expect(data.sex, 'Macho');
      expect(data.species, 'cattle');
      expect(data.locationCity, 'Uberaba');
      expect(data.locationState, 'MG');
      expect(data.locationDirections, 'Fazenda Boa Vista');
    });

    test('null city/state fall back to empty string, not null', () {
      final herd = HerdAnimal(
        id: 'a1',
        name: 'Imperador',
        breed: 'Nelore',
        sex: 'Macho',
        species: AnimalSpecies.cattle,
        available: true,
      );

      final data = AnimalDetailData.fromHerdAnimal(herd);

      expect(data.locationCity, '');
      expect(data.locationState, '');
    });
  });

  group('locationFull', () {
    test('joins non-empty parts with a comma', () {
      const data = AnimalDetailData(
        id: 'a1',
        name: 'X',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Macho',
        photoUrls: [],
        locationCity: 'Uberaba',
        locationState: 'MG',
      );

      expect(data.locationFull, 'Uberaba, MG');
    });

    test('empty state is omitted, not left as a trailing comma', () {
      const data = AnimalDetailData(
        id: 'a1',
        name: 'X',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Macho',
        photoUrls: [],
        locationCity: 'Uberaba',
        locationState: '',
      );

      expect(data.locationFull, 'Uberaba');
    });
  });

  group('ageLabel', () {
    test('singular for 1, plural otherwise, empty when null', () {
      const base = AnimalDetailData(
        id: 'a1',
        name: 'X',
        species: 'cattle',
        breed: 'Nelore',
        sex: 'Macho',
        photoUrls: [],
        locationCity: '',
        locationState: '',
      );

      expect(base.ageLabel, '');
      expect(
        AnimalDetailData(
          id: base.id,
          name: base.name,
          species: base.species,
          breed: base.breed,
          sex: base.sex,
          photoUrls: base.photoUrls,
          locationCity: base.locationCity,
          locationState: base.locationState,
          age: 1,
        ).ageLabel,
        '1 ano',
      );
      expect(
        AnimalDetailData(
          id: base.id,
          name: base.name,
          species: base.species,
          breed: base.breed,
          sex: base.sex,
          photoUrls: base.photoUrls,
          locationCity: base.locationCity,
          locationState: base.locationState,
          age: 4,
        ).ageLabel,
        '4 anos',
      );
    });
  });
}

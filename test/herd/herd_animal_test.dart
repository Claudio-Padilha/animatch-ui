import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/herd/domain/herd_animal.dart';

final _json = {
  'id': '1',
  'name': 'Touro X',
  'breed': 'nelore',
  'sex': 'male',
  'species': 'cattle',
  'status': 'active',
  'photoUrls': ['a.jpg'],
  'age': 3,
  'registration_number': 'REG1',
  'address': {
    'city': 'Uberaba',
    'state': 'MG',
    'zipCode': '38000',
    'directions': 'Fazenda X',
  },
  'description': 'desc',
  'geneticIndices': {'birth_weight': 30.5, 'conformacao': 8.0},
};

void main() {
  test('fromJson derives display labels, availability, and flattens address',
      () {
    final animal = HerdAnimal.fromJson(_json);

    expect(animal.name, 'Touro X');
    expect(animal.breed, 'Nelore');
    expect(animal.sex, 'Macho');
    expect(animal.available, isTrue); // status == 'active'
    expect(animal.location, 'Uberaba, MG');
    expect(animal.city, 'Uberaba');
    expect(animal.propertyName, 'Fazenda X'); // address.directions
    expect(animal.geneticIndices!.birthWeight, 30.5);
  });

  test('fromJson maps inactive status to unavailable', () {
    final animal = HerdAnimal.fromJson({..._json, 'status': 'inactive'});
    expect(animal.available, isFalse);
  });

  test('fromJson composes location from non-empty parts — "state only" when '
      'the city is masked (non-owner view of a free-tier animal)', () {
    final animal = HerdAnimal.fromJson({
      ..._json,
      'address': {'city': null, 'state': 'MG', 'zipCode': null},
    });
    expect(animal.location, 'MG');
    expect(animal.city, isNull);
    expect(animal.propertyName, isNull);
  });

  test('fromJson location is null when the whole address is absent', () {
    final animal = HerdAnimal.fromJson({..._json, 'address': null});
    expect(animal.location, isNull);
  });

  test('fromJson falls back to the raw API value when breed is not a known '
      'AnimalBreed enum value, instead of throwing', () {
    final animal =
        HerdAnimal.fromJson({..._json, 'breed': 'some_future_breed'});
    expect(animal.breed, 'some_future_breed');
  });

  test('generated equality treats same-value instances as equal', () {
    final a = HerdAnimal.fromJson(_json);
    final b = HerdAnimal.fromJson(_json);
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('copyWith replaces only the given field and leaves the original untouched',
      () {
    final original = HerdAnimal.fromJson(_json);
    final renamed = original.copyWith(name: 'Touro Y');

    expect(renamed.name, 'Touro Y');
    expect(renamed.id, original.id);
    expect(original.name, 'Touro X');
  });

  test('GeneticIndices.isEmpty', () {
    expect(const GeneticIndices().isEmpty, isTrue);
    expect(const GeneticIndices(birthWeight: 1).isEmpty, isFalse);
  });

  test('GeneticIndices.fromJson maps all fields, including conformacao',
      () {
    final indices = GeneticIndices.fromJson({
      'birth_weight': 30.5,
      'milk_restriction_weight': 180.0,
      'weight_18m': 320.0,
      'fertility_index': 12.5,
      'conformacao': 8.0,
    });

    expect(indices.birthWeight, 30.5);
    expect(indices.milkRestrictionWeight, 180.0);
    expect(indices.weight18m, 320.0);
    expect(indices.fertilityIndex, 12.5);
    expect(indices.conformacao, 8.0);
    expect(indices.isEmpty, isFalse);
  });
}

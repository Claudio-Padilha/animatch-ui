import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/herd/domain/animal_enums.dart';

void main() {
  group('AnimalBreed.label / fromLabel', () {
    test('capitalizes each word, lowercasing prepositions except the first '
        'word', () {
      expect(AnimalBreed.mangalargaMarchador.label, 'Mangalarga Marchador');
      expect(AnimalBreed.nelore.label, 'Nelore');
      // 'de' is in the lowercase-preposition exception list — stays
      // lowercase even though it's not the first word.
      expect(AnimalBreed.quartoDeMillha.label, 'Quarto de Milha');
    });

    test('fromLabel(label) round-trips for every enum value', () {
      for (final breed in AnimalBreed.values) {
        expect(
          AnimalBreed.fromLabel(breed.label),
          breed,
          reason: '${breed.name} -> "${breed.label}" -> should round-trip',
        );
      }
    });

    test('fromApiValue(apiValue) round-trips for every enum value', () {
      for (final breed in AnimalBreed.values) {
        expect(AnimalBreed.fromApiValue(breed.apiValue), breed);
      }
    });
  });

  group('AnimalSex.fromApiValue', () {
    test('maps known values', () {
      expect(AnimalSex.fromApiValue('male'), AnimalSex.male);
      expect(AnimalSex.fromApiValue('female'), AnimalSex.female);
    });

    test('defaults to male on an unknown value', () {
      expect(AnimalSex.fromApiValue('unknown'), AnimalSex.male);
    });
  });

  group('AnimalSex.displayLabel', () {
    test('4 combinations: male/female x cattle/horse', () {
      expect(
        AnimalSex.male.displayLabel(AnimalSpecies.cattle),
        'Touro',
      );
      expect(
        AnimalSex.female.displayLabel(AnimalSpecies.cattle),
        'Vaca',
      );
      expect(
        AnimalSex.male.displayLabel(AnimalSpecies.horse),
        'Garanhão',
      );
      expect(
        AnimalSex.female.displayLabel(AnimalSpecies.horse),
        'Égua',
      );
    });
  });

  group('AnimalSpecies.fromLabel / fromApiValue', () {
    test('round-trips for every enum value', () {
      for (final species in AnimalSpecies.values) {
        expect(AnimalSpecies.fromLabel(species.label), species);
        expect(AnimalSpecies.fromApiValue(species.apiValue), species);
      }
    });
  });
}

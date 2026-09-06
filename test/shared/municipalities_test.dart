import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/shared/domain/municipalities.dart';

void main() {
  group('Municipalities.fromJson', () {
    test('parses a state -> cities map', () {
      final municipalities = Municipalities.fromJson({
        'MG': ['Uberaba', 'Uberlândia'],
        'SP': ['Ribeirão Preto'],
      });

      expect(municipalities.citiesOf('MG'), ['Uberaba', 'Uberlândia']);
      expect(municipalities.citiesOf('SP'), ['Ribeirão Preto']);
    });
  });

  group('states', () {
    test('returns keys sorted alphabetically regardless of JSON order', () {
      final municipalities = Municipalities.fromJson({
        'SP': ['Ribeirão Preto'],
        'MG': ['Uberaba'],
        'BA': ['Salvador'],
      });

      expect(municipalities.states, ['BA', 'MG', 'SP']);
    });
  });

  group('citiesOf', () {
    test('returns an empty list for an unknown state rather than throwing',
        () {
      final municipalities = Municipalities.fromJson({
        'MG': ['Uberaba'],
      });

      expect(municipalities.citiesOf('ZZ'), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/shared/domain/distance_range.dart';

void main() {
  group('label / maxKm', () {
    test('every value has the expected label and maxKm pairing', () {
      final expected = {
        DistanceRange.upTo50: ('Até 50 km', 50),
        DistanceRange.upTo100: ('Até 100 km', 100),
        DistanceRange.upTo250: ('Até 250 km', 250),
        DistanceRange.upTo500: ('Até 500 km', 500),
        DistanceRange.upTo1000: ('Até 1.000 km', 1000),
      };

      for (final entry in expected.entries) {
        expect(entry.key.label, entry.value.$1);
        expect(entry.key.maxKm, entry.value.$2);
      }
      expect(DistanceRange.any.label, 'Qualquer distância');
      expect(DistanceRange.any.maxKm, isNull);
    });
  });

  group('fromLabel', () {
    test('round-trips every value through its label', () {
      for (final range in DistanceRange.values) {
        expect(DistanceRange.fromLabel(range.label), range);
      }
    });
  });
}

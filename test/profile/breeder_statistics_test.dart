import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/profile/domain/breeder_statistics.dart';

void main() {
  group('BreederStatistics.fromJson', () {
    test('maps camelCase keys', () {
      final stats = BreederStatistics.fromJson({
        'activeAnimals': 5,
        'likes': 12,
        'breederMatches': 3,
      });

      expect(stats.activeAnimals, 5);
      expect(stats.likes, 12);
      expect(stats.breederMatches, 3);
    });
  });
}

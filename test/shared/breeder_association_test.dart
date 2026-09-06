import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/shared/domain/association.dart';
import 'package:animatch/shared/domain/breeder_association.dart';

void main() {
  group('BreederAssociation.fromJson/toJson', () {
    test('round-trips with all fields present — the association item uses a '
        'snake_case registration_number key (activate DTO)', () {
      final association = BreederAssociation.fromJson({
        'code': 'ABCZ',
        'name': 'Associação Brasileira dos Criadores de Zebu',
        'registration_number': 'REG123',
      });

      expect(association.code, 'ABCZ');
      expect(association.name, 'Associação Brasileira dos Criadores de Zebu');
      expect(association.registrationNumber, 'REG123');
      expect(association.toJson(), {
        'code': 'ABCZ',
        'registration_number': 'REG123',
      });
    });

    test('fromJson still tolerates a camelCase registrationNumber key', () {
      final association = BreederAssociation.fromJson({
        'code': 'ABCZ',
        'registrationNumber': 'REG123',
      });
      expect(association.registrationNumber, 'REG123');
    });

    test('name falls back to code when absent', () {
      final association = BreederAssociation.fromJson({'code': 'ABCZ'});

      expect(association.name, 'ABCZ');
    });

    test('toJson omits registrationNumber when null', () {
      const association = BreederAssociation(code: 'ABCZ', name: 'ABCZ');

      expect(association.toJson(), {'code': 'ABCZ'});
    });
  });

  group('Association.fromJson', () {
    test('parses code and name', () {
      final association =
          Association.fromJson({'code': 'ABCZ', 'name': 'ABCZ Assoc'});

      expect(association.code, 'ABCZ');
      expect(association.name, 'ABCZ Assoc');
    });

    test('name falls back to code when absent', () {
      final association = Association.fromJson({'code': 'ABCZ'});

      expect(association.name, 'ABCZ');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/shared/domain/breeder_association.dart';

final _json = {
  'id': '1',
  'name': 'Fulano de Tal',
  'email': 'fulano@example.com',
  'pictureUrl': 'https://example.com/pic.jpg',
  'phone': '31999999999',
  'propertyName': 'Fazenda Boa Vista',
  'city': 'Uberaba',
  'state': 'MG',
  'associationId': 'assoc-1',
  'profileStatus': 'active',
};

void main() {
  group('Breeder.fromJson', () {
    test('maps pictureUrl to avatarUrl and propertyName to farmName', () {
      final breeder = Breeder.fromJson(_json);

      expect(breeder.avatarUrl, 'https://example.com/pic.jpg');
      expect(breeder.farmName, 'Fazenda Boa Vista');
    });

    test('maps profileStatus to status via BreederStatus.fromJson', () {
      final breeder = Breeder.fromJson(_json);
      expect(breeder.status, BreederStatus.active);
    });

    test('defaults associations to an empty list when absent from JSON', () {
      final json = {..._json}..remove('profileStatus');
      final breeder = Breeder.fromJson(json);
      expect(breeder.associations, isEmpty);
    });
  });

  group('BreederStatus.fromJson', () {
    final cases = <String?, BreederStatus>{
      'active': BreederStatus.active,
      'rejected': BreederStatus.rejected,
      'pending_activation': BreederStatus.pending,
      'some_unknown_value': BreederStatus.pending,
      null: BreederStatus.pending,
    };

    for (final entry in cases.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(BreederStatus.fromJson(entry.key), entry.value);
      });
    }
  });

  group('copyWith', () {
    test('updates id and email without regressing the historical M-1 bug',
        () {
      final original = Breeder.fromJson(_json);
      final updated = original.copyWith(id: '2', email: 'novo@example.com');

      expect(updated.id, '2');
      expect(updated.email, 'novo@example.com');
      expect(original.id, '1');
      expect(original.email, 'fulano@example.com');
    });
  });

  group('verifiedBreeder', () {
    test('is true when status is active', () {
      final breeder = Breeder.fromJson({..._json, 'profileStatus': 'active'});
      expect(breeder.verifiedBreeder, isTrue);
    });

    test('is false when status is pending', () {
      final breeder =
          Breeder.fromJson({..._json, 'profileStatus': 'pending_activation'});
      expect(breeder.verifiedBreeder, isFalse);
    });

    test('is false when status is rejected', () {
      final breeder =
          Breeder.fromJson({..._json, 'profileStatus': 'rejected'});
      expect(breeder.verifiedBreeder, isFalse);
    });
  });

  group('generated equality', () {
    test('two instances built with identical field values are equal', () {
      const a = Breeder(
        id: '1',
        name: 'Fulano de Tal',
        email: 'fulano@example.com',
        associations: [BreederAssociation(code: 'abcz', name: 'ABCZ')],
        status: BreederStatus.active,
      );
      const b = Breeder(
        id: '1',
        name: 'Fulano de Tal',
        email: 'fulano@example.com',
        associations: [BreederAssociation(code: 'abcz', name: 'ABCZ')],
        status: BreederStatus.active,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a differing field makes instances unequal', () {
      const a = Breeder(
        id: '1',
        name: 'Fulano de Tal',
        email: 'fulano@example.com',
      );
      const b = Breeder(
        id: '1',
        name: 'Outro Nome',
        email: 'fulano@example.com',
      );

      expect(a == b, isFalse);
    });
  });
}

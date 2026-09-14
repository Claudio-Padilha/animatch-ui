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

    test('round-trips documentUrl via the snake_case document_url key', () {
      final association = BreederAssociation.fromJson({
        'code': 'ABCZ',
        'document_url': 'https://cdn.example.com/carteirinha.jpg',
      });

      expect(
          association.documentUrl, 'https://cdn.example.com/carteirinha.jpg');
      expect(association.toJson(), {
        'code': 'ABCZ',
        'document_url': 'https://cdn.example.com/carteirinha.jpg',
      });
    });

    test('fromJson still tolerates a camelCase documentUrl key', () {
      final association = BreederAssociation.fromJson({
        'code': 'ABCZ',
        'documentUrl': 'https://cdn.example.com/carteirinha.jpg',
      });
      expect(
          association.documentUrl, 'https://cdn.example.com/carteirinha.jpg');
    });

    test('name falls back to code when absent', () {
      final association = BreederAssociation.fromJson({'code': 'ABCZ'});

      expect(association.name, 'ABCZ');
    });

    test('toJson omits registrationNumber when null', () {
      const association = BreederAssociation(code: 'ABCZ', name: 'ABCZ');

      expect(association.toJson(), {'code': 'ABCZ'});
    });

    test('verificationStatus defaults to unsubmitted when absent', () {
      final association = BreederAssociation.fromJson({'code': 'ABCZ'});

      expect(association.verificationStatus,
          AssociationVerificationStatus.unsubmitted);
      expect(association.rejectionReason, isNull);
    });

    test('fromJson parses each verificationStatus value', () {
      for (final entry in {
        'pending': AssociationVerificationStatus.pending,
        'approved': AssociationVerificationStatus.approved,
        'rejected': AssociationVerificationStatus.rejected,
      }.entries) {
        final association = BreederAssociation.fromJson({
          'code': 'ABCZ',
          'verificationStatus': entry.key,
        });
        expect(association.verificationStatus, entry.value);
      }
    });

    test('fromJson parses rejectionReason', () {
      final association = BreederAssociation.fromJson({
        'code': 'ABCZ',
        'verificationStatus': 'rejected',
        'rejectionReason': 'Foto ilegível',
      });

      expect(association.verificationStatus,
          AssociationVerificationStatus.rejected);
      expect(association.rejectionReason, 'Foto ilegível');
    });

    test(
        'toJson never sends verificationStatus/rejectionReason — admin-only '
        'fields', () {
      final association = BreederAssociation.fromJson({
        'code': 'ABCZ',
        'verificationStatus': 'approved',
        'rejectionReason': null,
      });

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

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:animatch/features/profile/data/profile_repository.dart';
import 'package:animatch/shared/domain/breeder_association.dart';

const _breederJson = {
  'id': 'b1',
  'name': 'Fazenda X',
  'email': 'x@example.com',
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late ProfileRepository repo;

  setUp(() {
    dio = Dio(BaseOptions());
    adapter = DioAdapter(dio: dio);
    repo = ProfileRepository(dio);
  });

  group('getAssociations', () {
    test('GETs /associations and parses the list', () async {
      adapter.onGet(
        '/associations',
        (server) => server.reply(200, [
          {'code': 'ABCZ', 'name': 'ABCZ'},
        ]),
      );
      final associations = await repo.getAssociations();
      expect(associations.single.code, 'ABCZ');
    });
  });

  group('getStatistics', () {
    test('GETs /breeders/statistic and parses BreederStatistics', () async {
      adapter.onGet(
        '/breeders/statistic',
        (server) => server.reply(200, {
          'activeAnimals': 2,
          'likes': 1,
          'breederMatches': 0,
        }),
      );
      final stats = await repo.getStatistics();
      expect(stats.activeAnimals, 2);
    });
  });

  group('activate', () {
    test('PATCHes /breeders/:id/activate with conditional fields included '
        'only when non-empty/non-null', () async {
      adapter.onPatch(
        '/breeders/b1/activate',
        (server) => server.reply(200, _breederJson),
        data: {'name': 'João', 'phone': '119999999'},
      );

      await repo.activate(breederId: 'b1', name: 'João', phone: '119999999');
    });

    test('includes cpf/propertyName/associations/pictureUrl when provided',
        () async {
      adapter.onPatch(
        '/breeders/b1/activate',
        (server) => server.reply(200, _breederJson),
        data: {
          'name': 'João',
          'phone': '119999999',
          'cpf': '12345678901',
          'propertyName': 'Fazenda Boa Vista',
          'associations': [
            {'code': 'ABCZ'},
          ],
          'pictureUrl': 'http://img',
        },
      );

      await repo.activate(
        breederId: 'b1',
        name: 'João',
        phone: '119999999',
        cpf: '12345678901',
        farmName: 'Fazenda Boa Vista',
        associations: const [BreederAssociation(code: 'ABCZ', name: 'ABCZ')],
        pictureUrl: 'http://img',
      );
    });
  });

  group('updateProfile', () {
    test('all optional fields empty -> no address key at all', () async {
      adapter.onPatch(
        '/breeders/b1',
        (server) => server.reply(200, _breederJson),
        data: {'name': 'João'},
      );

      await repo.updateProfile(breederId: 'b1', name: 'João');
    });

    test('one address field set -> address present with only that key',
        () async {
      adapter.onPatch(
        '/breeders/b1',
        (server) => server.reply(200, _breederJson),
        data: {
          'name': 'João',
          'address': {'city': 'Uberaba'},
        },
      );

      await repo.updateProfile(breederId: 'b1', name: 'João', city: 'Uberaba');
    });

    test('associations: null -> key omitted (backend set left untouched)',
        () async {
      adapter.onPatch(
        '/breeders/b1',
        (server) => server.reply(200, _breederJson),
        data: {'name': 'João'},
      );

      await repo.updateProfile(breederId: 'b1', name: 'João');
    });

    test('associations: a list -> sent as [{code, registration_number?}] '
        '(replaces the whole set); [] clears it', () async {
      adapter.onPatch(
        '/breeders/b1',
        (server) => server.reply(200, _breederJson),
        data: {
          'name': 'João',
          'associations': [
            {'code': 'ABCZ', 'registration_number': 'R1'},
            {'code': 'ABQM'},
          ],
        },
      );

      await repo.updateProfile(
        breederId: 'b1',
        name: 'João',
        associations: const [
          BreederAssociation(code: 'ABCZ', name: 'ABCZ', registrationNumber: 'R1'),
          BreederAssociation(code: 'ABQM', name: 'ABQM'),
        ],
      );

      adapter.onPatch(
        '/breeders/b1',
        (server) => server.reply(200, _breederJson),
        data: {'name': 'João', 'associations': <dynamic>[]},
      );
      await repo.updateProfile(
        breederId: 'b1',
        name: 'João',
        associations: const [],
      );
    });

    test('all address fields set -> address includes all of them', () async {
      adapter.onPatch(
        '/breeders/b1',
        (server) => server.reply(200, _breederJson),
        data: {
          'name': 'João',
          'address': {
            'directions': 'Fazenda Boa Vista',
            'zipCode': '12345000',
            'city': 'Uberaba',
            'state': 'MG',
          },
        },
      );

      await repo.updateProfile(
        breederId: 'b1',
        name: 'João',
        directions: 'Fazenda Boa Vista',
        zipCode: '12345000',
        city: 'Uberaba',
        state: 'MG',
      );
    });
  });
}

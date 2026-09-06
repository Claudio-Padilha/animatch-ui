import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:animatch/features/matches/data/match_repository.dart';

const _matchJson = {
  'id': 'm1',
  'status': 'pending',
  'createdAt': '2026-08-01T00:00:00.000Z',
  'firstAnimal': {'id': 'a1', 'name': 'Trovão'},
  'secondAnimal': {'id': 'a2', 'name': 'Estrela'},
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late MatchRepository repo;

  setUp(() {
    dio = Dio(BaseOptions());
    adapter = DioAdapter(dio: dio);
    repo = MatchRepository(dio);
  });

  group('getMatches', () {
    test('GETs /matches with animalId query param and parses via '
        'MatchItem.fromJson(e, animalId: animalId)', () async {
      adapter.onGet(
        '/matches',
        (server) => server.reply(200, [_matchJson]),
        queryParameters: {'animalId': 'a1'},
      );

      final matches = await repo.getMatches('a1');

      expect(matches, hasLength(1));
      expect(matches.single.id, 'm1');
      // Confirms the repo actually forwards its animalId arg into
      // fromJson's yours/theirs resolution (fixture's firstAnimal.id is
      // 'a1', the same id passed to getMatches).
      expect(matches.single.yourAnimal.name, 'Trovão');
    });
  });

  group('confirmMatch', () {
    test('PATCHes /matches/:id/status with status: confirmed and returns '
        'the parsed payload', () async {
      adapter.onPatch(
        '/matches/m1/status',
        (server) => server.reply(200, {'id': 'm1', 'status': 'confirmed'}),
        data: {'status': 'confirmed'},
      );

      final result = await repo.confirmMatch('m1');

      expect(result, {'id': 'm1', 'status': 'confirmed'});
    });
  });

  group('rejectMatch', () {
    test('PATCHes /matches/:id/status with status: rejected, returns void',
        () async {
      adapter.onPatch(
        '/matches/m1/status',
        (server) => server.reply(200, null),
        data: {'status': 'rejected'},
      );

      await repo.rejectMatch('m1');
    });
  });

  group('createMatch', () {
    test('POSTs firstLikeAnimalId/secondLikeAnimalId/optional status',
        () async {
      adapter.onPost(
        '/matches',
        (server) => server.reply(201, {'id': 'm2', 'status': 'pending'}),
        data: {
          'firstLikeAnimalId': 'a1',
          'secondLikeAnimalId': 'a2',
          'status': 'rejected',
        },
      );

      final result = await repo.createMatch(
        firstLikeAnimalId: 'a1',
        secondLikeAnimalId: 'a2',
        status: 'rejected',
      );

      expect(result, {'id': 'm2', 'status': 'pending'});
    });

    test('omits status entirely when not provided', () async {
      adapter.onPost(
        '/matches',
        (server) => server.reply(201, {'id': 'm2', 'status': 'pending'}),
        data: {'firstLikeAnimalId': 'a1', 'secondLikeAnimalId': 'a2'},
      );

      final result = await repo.createMatch(
        firstLikeAnimalId: 'a1',
        secondLikeAnimalId: 'a2',
      );

      expect(result['id'], 'm2');
    });
  });

  group('deleteMatch', () {
    test('DELETEs /matches/:id', () async {
      adapter.onDelete('/matches/m1', (server) => server.reply(200, null));
      await repo.deleteMatch('m1');
    });
  });

  group('getChatToken', () {
    test('POSTs /matches/:id/chat-token with no breederId (derived from token)',
        () async {
      adapter.onPost(
        '/matches/m1/chat-token',
        (server) => server.reply(200, {
          'token': 'tok',
          'channelId': 'ch1',
          'channelType': 'messaging',
        }),
      );

      final result = await repo.getChatToken('m1');

      expect(result['token'], 'tok');
      expect(result['channelId'], 'ch1');
    });
  });

  group('getMatch', () {
    test('GETs /matches/:id and parses the reshaped detail payload via '
        'MatchItem.fromDetailJson', () async {
      adapter.onGet(
        '/matches/m1',
        (server) => server.reply(200, {
          'id': 'm1',
          'status': 'confirmed',
          'createdAt': '2026-08-01T00:00:00.000Z',
          'yourAnimal': {'id': 'a1', 'name': 'Trovão', 'breed': 'nelore', 'sex': 'male'},
          'theirAnimal': {'id': 'a2', 'name': 'Estrela', 'breed': 'nelore', 'sex': 'female'},
          'theirBreeder': {
            'name': 'Maria',
            'phone': '5511999999999',
            'email': 'maria@example.com',
          },
        }),
      );

      final match = await repo.getMatch('m1');

      expect(match.id, 'm1');
      expect(match.yourAnimal.name, 'Trovão');
      expect(match.theirAnimal.name, 'Estrela');
      expect(match.contact.breederName, 'Maria');
      expect(match.contact.phone, '5511999999999');
      expect(match.contact.email, 'maria@example.com');
    });
  });
}

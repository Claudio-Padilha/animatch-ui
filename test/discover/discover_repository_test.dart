import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:animatch/features/discover/data/discover_repository.dart';

void main() {
  group('getSuggestions', () {
    test('GETs /matches/suggestions/:animalId and parses the list',
        () async {
      final dio = Dio(BaseOptions());
      final adapter = DioAdapter(dio: dio);
      adapter.onGet(
        '/matches/suggestions/a1',
        (server) => server.reply(200, [
          {
            'id': 'cand1',
            'name': 'Estrela',
            'breed': 'nelore',
            'sex': 'female',
          },
        ]),
      );
      final repo = DiscoverRepository(dio);

      final suggestions = await repo.getSuggestions('a1');

      expect(suggestions, hasLength(1));
      expect(suggestions.single.id, 'cand1');
    });
  });
}

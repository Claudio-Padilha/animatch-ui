import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:animatch/features/herd/data/herd_repository.dart';

const _animalJson = {
  'id': 'a1',
  'name': 'Trovão',
  'species': 'cattle',
  'breed': 'nelore',
  'sex': 'male',
  'status': 'active',
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late HerdRepository repo;

  setUp(() {
    dio = Dio(BaseOptions());
    adapter = DioAdapter(dio: dio);
    repo = HerdRepository(dio);
  });

  group('getAnimals', () {
    test('GETs /animals (no query params — owner derived from token) and '
        'parses the list', () async {
      adapter.onGet(
        '/animals',
        (server) => server.reply(200, [_animalJson]),
      );

      final animals = await repo.getAnimals();

      expect(animals, hasLength(1));
      expect(animals.single.id, 'a1');
      expect(animals.single.name, 'Trovão');
    });
  });

  group('getAnimal', () {
    test('GETs /animals/:id and parses a single object', () async {
      adapter.onGet('/animals/a1', (server) => server.reply(200, _animalJson));

      final animal = await repo.getAnimal('a1');

      expect(animal.id, 'a1');
    });
  });

  group('addAnimal', () {
    test('POSTs the payload as-is to /animals and returns the parsed animal',
        () async {
      final payload = {'name': 'Trovão', 'species': 'cattle'};
      adapter.onPost(
        '/animals',
        (server) => server.reply(201, _animalJson),
        data: payload,
      );

      final animal = await repo.addAnimal(payload);

      expect(animal.id, 'a1');
    });
  });

  group('updateAnimal', () {
    test('PATCHes /animals/:id with the payload and returns the parsed animal',
        () async {
      final payload = {'name': 'Novo Nome'};
      adapter.onPatch(
        '/animals/a1',
        (server) => server.reply(200, _animalJson),
        data: payload,
      );

      final animal = await repo.updateAnimal('a1', payload);

      expect(animal.id, 'a1');
    });
  });

  group('deleteAnimal', () {
    test('DELETEs /animals/:id', () async {
      adapter.onDelete('/animals/a1', (server) => server.reply(200, null));

      await repo.deleteAnimal('a1');
      // No exception thrown is the assertion here.
    });
  });

  // The repository layer has no try/catch — errors must bubble up as
  // DioException so AsyncValue.guard (in HerdNotifier et al.) can catch
  // them. A future accidental try/catch addition here would silently
  // break every herd screen's error state.
  group('errors propagate as DioException, not swallowed', () {
    test('getAnimals', () async {
      adapter.onGet(
        '/animals',
        (server) => server.throws(
          500,
          DioException(
            requestOptions: RequestOptions(path: '/animals'),
            type: DioExceptionType.badResponse,
          ),
        ),
      );
      expect(() => repo.getAnimals(), throwsA(isA<DioException>()));
    });

    test('getAnimal', () async {
      adapter.onGet(
        '/animals/a1',
        (server) => server.throws(
          404,
          DioException(
            requestOptions: RequestOptions(path: '/animals/a1'),
            type: DioExceptionType.badResponse,
          ),
        ),
      );
      expect(() => repo.getAnimal('a1'), throwsA(isA<DioException>()));
    });

    test('addAnimal', () async {
      adapter.onPost(
        '/animals',
        (server) => server.throws(
          400,
          DioException(
            requestOptions: RequestOptions(path: '/animals'),
            type: DioExceptionType.badResponse,
          ),
        ),
      );
      expect(() => repo.addAnimal({}), throwsA(isA<DioException>()));
    });

    test('updateAnimal', () async {
      adapter.onPatch(
        '/animals/a1',
        (server) => server.throws(
          400,
          DioException(
            requestOptions: RequestOptions(path: '/animals/a1'),
            type: DioExceptionType.badResponse,
          ),
        ),
      );
      expect(() => repo.updateAnimal('a1', {}), throwsA(isA<DioException>()));
    });

    test('deleteAnimal', () async {
      adapter.onDelete(
        '/animals/a1',
        (server) => server.throws(
          500,
          DioException(
            requestOptions: RequestOptions(path: '/animals/a1'),
            type: DioExceptionType.badResponse,
          ),
        ),
      );
      expect(() => repo.deleteAnimal('a1'), throwsA(isA<DioException>()));
    });
  });
}

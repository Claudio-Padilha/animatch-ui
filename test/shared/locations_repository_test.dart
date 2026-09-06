import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:animatch/features/locations/data/locations_repository.dart';
import 'package:animatch/features/locations/providers/locations_provider.dart';
import 'package:animatch/shared/domain/municipalities.dart';

void main() {
  group('LocationsRepository.getMunicipalities', () {
    test('GETs /locations/municipalities and parses via Municipalities.fromJson',
        () async {
      final dio = Dio(BaseOptions());
      final adapter = DioAdapter(dio: dio);
      adapter.onGet(
        '/locations/municipalities',
        (server) => server.reply(200, {
          'MG': ['Uberaba'],
        }),
      );
      final repo = LocationsRepository(dio);

      final municipalities = await repo.getMunicipalities();

      expect(municipalities.citiesOf('MG'), ['Uberaba']);
    });
  });

  group('municipalitiesProvider', () {
    test('is fetched once per session — a second watch does not re-fetch',
        () async {
      var callCount = 0;
      final container = ProviderContainer(overrides: [
        locationsRepositoryProvider.overrideWithValue(
          _CountingLocationsRepository(() => callCount++),
        ),
      ]);
      addTearDown(container.dispose);

      await container.read(municipalitiesProvider.future);
      await container.read(municipalitiesProvider.future);
      container.read(municipalitiesProvider);

      expect(callCount, 1);
    });
  });
}

class _CountingLocationsRepository extends LocationsRepository {
  _CountingLocationsRepository(this._onCall) : super(Dio());

  final void Function() _onCall;

  @override
  Future<Municipalities> getMunicipalities() async {
    _onCall();
    return Municipalities.fromJson({
      'MG': ['Uberaba'],
    });
  }
}

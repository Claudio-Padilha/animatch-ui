import 'package:dio/dio.dart';

import '../../../shared/domain/municipalities.dart';

class LocationsRepository {
  const LocationsRepository(this._dio);

  final Dio _dio;

  Future<Municipalities> getMunicipalities() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/locations/municipalities');
    return Municipalities.fromJson(response.data!);
  }
}

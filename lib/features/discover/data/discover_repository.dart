import 'package:dio/dio.dart';

import '../domain/discover_animal.dart';

class DiscoverRepository {
  const DiscoverRepository(this._dio);

  final Dio _dio;

  Future<List<DiscoverAnimal>> getSuggestions(String animalId) async {
    final response = await _dio.get<List<dynamic>>(
      '/matches/suggestions/$animalId',
    );
    return (response.data as List)
        .map((e) => DiscoverAnimal.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

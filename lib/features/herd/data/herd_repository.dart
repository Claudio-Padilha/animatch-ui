import 'package:dio/dio.dart';

import '../domain/herd_animal.dart';

class HerdRepository {
  const HerdRepository(this._dio);

  final Dio _dio;

  Future<List<HerdAnimal>> getAnimals(String breederId) async {
    final response = await _dio.get<List<dynamic>>(
      '/animals',
      queryParameters: {'breederId': breederId},
    );
    return (response.data as List)
        .map((e) => HerdAnimal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<HerdAnimal> getAnimal(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/animals/$id');
    return HerdAnimal.fromJson(response.data!);
  }

  Future<HerdAnimal> addAnimal(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/animals',
      data: payload,
      options: Options(contentType: 'application/json'),
    );
    return HerdAnimal.fromJson(response.data!);
  }

  Future<HerdAnimal> updateAnimal(
      String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/animals/$id',
      data: payload,
      options: Options(contentType: 'application/json'),
    );
    return HerdAnimal.fromJson(response.data!);
  }

  Future<void> deleteAnimal(String id) =>
      _dio.delete<void>('/animals/$id');
}

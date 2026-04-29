import 'package:dio/dio.dart';

import '../domain/match_item.dart';

class MatchRepository {
  const MatchRepository(this._dio);

  final Dio _dio;

  Future<List<MatchItem>> getMatches(String animalId) async {
    final response = await _dio.get<List<dynamic>>(
      '/matches',
      queryParameters: {'animalId': animalId},
    );
    return (response.data as List)
        .map((e) => MatchItem.fromJson(
              e as Map<String, dynamic>,
              animalId: animalId,
            ))
        .toList();
  }

  /// Returns the raw match payload (contains at minimum `id` and `status`).
  Future<Map<String, dynamic>> confirmMatch(String matchId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/matches/$matchId/status',
      data: {'status': 'confirmed'},
      options: Options(contentType: 'application/json'),
    );
    return response.data ?? {};
  }

  Future<void> rejectMatch(String matchId) => _dio.patch<void>(
        '/matches/$matchId/status',
        data: {'status': 'rejected'},
        options: Options(contentType: 'application/json'),
      );

  Future<void> deleteMatch(String matchId) =>
      _dio.delete<void>('/matches/$matchId');

  Future<Map<String, dynamic>> getChatToken(
    String matchId, {
    required String breederId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/matches/$matchId/chat-token',
      queryParameters: {'breederId': breederId},
    );
    return response.data ?? {};
  }

  /// Returns the raw match payload (contains at minimum `id` and `status`).
  Future<Map<String, dynamic>> createMatch({
    required String firstLikeAnimalId,
    required String secondLikeAnimalId,
    String? status,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/matches',
      data: {
        'firstLikeAnimalId': firstLikeAnimalId,
        'secondLikeAnimalId': secondLikeAnimalId,
        'status': ?status,
      },
      options: Options(contentType: 'application/json'),
    );
    return response.data ?? {};
  }
}

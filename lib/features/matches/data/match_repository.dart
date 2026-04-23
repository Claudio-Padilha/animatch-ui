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

  Future<void> confirmMatch(String matchId) => _updateStatus(matchId, 'confirmed');

  Future<void> rejectMatch(String matchId) => _updateStatus(matchId, 'rejected');

  Future<void> _updateStatus(String matchId, String status) => _dio.patch<void>(
        '/matches/$matchId/status',
        data: {'status': status},
        options: Options(contentType: 'application/json'),
      );

  Future<void> createMatch({
    required String firstLikeAnimalId,
    required String secondLikeAnimalId,
    String? status,
  }) =>
      _dio.post<void>(
        '/matches',
        data: {
          'firstLikeAnimalId': firstLikeAnimalId,
          'secondLikeAnimalId': secondLikeAnimalId,
          'status': ?status,
        },
        options: Options(contentType: 'application/json'),
      );
}

import 'package:dio/dio.dart';

import '../domain/match_item.dart';

class MatchRepository {
  const MatchRepository(this._dio);

  final Dio _dio;

  /// List of matches for one of the caller's own animals. The backend 403s if
  /// `animalId` isn't owned by the token holder. This list shape does **not**
  /// carry breeder contact info — see [getMatch] / [MatchItem.fromDetailJson].
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

  /// A single match, resolved server-side against the authenticated breeder.
  /// Participant-only (403 otherwise). `theirBreeder.email`/`phone` are only
  /// present when the match is confirmed. Works from just a match id, so it
  /// also backs push-tap / deep-link / OS-restoration recovery.
  Future<MatchItem> getMatch(String matchId) async {
    final response = await _dio.get<Map<String, dynamic>>('/matches/$matchId');
    return MatchItem.fromDetailJson(response.data!);
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

  Future<Map<String, dynamic>> getChatToken(String matchId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/matches/$matchId/chat-token',
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

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:animatch/core/network/api_exception.dart';

DioException _dioError(int status, {Object? body}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: body,
      ),
    );

void main() {
  group('ApiException', () {
    test('classifies 401 / 403 / 404', () {
      expect(ApiException(_dioError(401)).isUnauthorized, isTrue);
      expect(ApiException(_dioError(403)).isForbidden, isTrue);
      expect(ApiException(_dioError(404)).isNotFound, isTrue);
    });

    test('needsProfile is true only for a 403 with the "Breeder profile '
        'required" message', () {
      final needsProfile = ApiException(
        _dioError(403, body: {'message': 'Breeder profile required'}),
      );
      expect(needsProfile.needsProfile, isTrue);
      expect(needsProfile.isForbiddenResource, isFalse);

      final ownership = ApiException(
        _dioError(403, body: {'message': 'Forbidden'}),
      );
      expect(ownership.needsProfile, isFalse);
      expect(ownership.isForbiddenResource, isTrue);

      final notForbidden = ApiException(
        _dioError(404, body: {'message': 'Breeder profile required'}),
      );
      expect(notForbidden.needsProfile, isFalse);
    });

    test('tolerates a non-map / missing body', () {
      expect(ApiException(_dioError(403)).serverMessage, isNull);
      expect(ApiException(_dioError(403, body: 'plain text')).serverMessage,
          isNull);
    });
  });
}

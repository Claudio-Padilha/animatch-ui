import 'dart:convert';
import 'dart:typed_data';

import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:animatch/features/auth/data/auth_repository.dart';

// A minimal HttpClientAdapter that runs a test-supplied handler instead of
// making a real request — no mocking package needed.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);
  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      _handler(options);

  @override
  void close({bool force = false}) {}
}

Dio _dioReturning(int statusCode, Map<String, dynamic> body) {
  return Dio()
    ..httpClientAdapter = _FakeAdapter((options) async => ResponseBody.fromString(
          jsonEncode(body),
          statusCode,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ));
}

Dio _dioThrowing(DioExceptionType type, {int? statusCode}) {
  return Dio()
    ..httpClientAdapter = _FakeAdapter((options) async => throw DioException(
          requestOptions: options,
          type: type,
          response: statusCode != null
              ? Response(requestOptions: options, statusCode: statusCode)
              : null,
        ));
}

// Captures the request body/query params instead of returning canned data —
// used by syncBreeder's payload-shape tests.
class _CapturingDio {
  _CapturingDio(int statusCode, Map<String, dynamic> responseBody) {
    dio = Dio()
      ..httpClientAdapter = _FakeAdapter((options) async {
        capturedData = options.data as Map<String, dynamic>?;
        return ResponseBody.fromString(
          jsonEncode(responseBody),
          statusCode,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });
  }

  late final Dio dio;
  Map<String, dynamic>? capturedData;
}

class MockAuth0 extends Mock implements Auth0 {}

class MockWebAuthentication extends Mock implements WebAuthentication {}

class MockCredentialsManager extends Mock implements CredentialsManager {}

Credentials _credentials({
  String sub = 'auth0|123',
  String? email,
  String? name,
  String? nickname,
}) =>
    Credentials(
      idToken: 'id-token',
      accessToken: 'access-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      user: UserProfile(sub: sub, email: email, name: name, nickname: nickname),
      tokenType: 'Bearer',
    );

void main() {
  // AuthRepository builds its own Auth0 client internally by default, but
  // accepts an injected Auth0 (added specifically to unblock this file —
  // see the M-3/M-4 notes in docs/production-review.md and the infra item
  // in docs/testing-plan.md §2.2).
  group('refreshBreeder', () {
    test('returns the parsed Breeder on success', () async {
      final repo = AuthRepository(_dioReturning(200, {
        'id': '1',
        'name': 'Fazenda X',
        'email': 'x@example.com',
      }));

      final breeder = await repo.refreshBreeder();

      expect(breeder, isNotNull);
      expect(breeder!.id, '1');
      expect(breeder.name, 'Fazenda X');
    });

    test('returns null on a network error, not an exception', () async {
      final repo = AuthRepository(_dioThrowing(DioExceptionType.connectionError));
      expect(await repo.refreshBreeder(), isNull);
    });

    test('returns null on a 5xx response', () async {
      final repo = AuthRepository(_dioReturning(500, {'error': 'boom'}));
      expect(await repo.refreshBreeder(), isNull);
    });
  });

  group('syncBreeder', () {
    test('posts name and address, response includes city -> passed through',
        () async {
      final capturing = _CapturingDio(200, {
        'id': '1',
        'name': 'João',
        'email': 'x@example.com',
        'address': {'city': 'Uberaba', 'state': 'MG'},
      });
      final repo = AuthRepository(capturing.dio);

      final breeder = await repo.syncBreeder(
        name: 'João',
        city: 'Uberaba',
        state: 'MG',
        zipCode: '12345000',
        directions: 'Fazenda Boa Vista',
      );

      expect(capturing.capturedData, {
        'name': 'João',
        'address': {
          'city': 'Uberaba',
          'state': 'MG',
          'zipCode': '12345000',
          'directions': 'Fazenda Boa Vista',
        },
      });
      expect(breeder.city, 'Uberaba');
      expect(breeder.state, 'MG');
    });

    test('omits directions from the payload when empty', () async {
      final capturing = _CapturingDio(200, {
        'id': '1',
        'name': 'João',
        'email': 'x@example.com',
      });
      final repo = AuthRepository(capturing.dio);

      await repo.syncBreeder(
        name: 'João',
        city: 'Uberaba',
        state: 'MG',
        zipCode: '12345000',
      );

      final address = capturing.capturedData!['address'] as Map;
      expect(address.containsKey('directions'), isFalse);
    });

    test('response omits city -> merges the form city/state back in',
        () async {
      final capturing = _CapturingDio(200, {
        'id': '1',
        'name': 'João',
        'email': 'x@example.com',
        // No address in the response at all.
      });
      final repo = AuthRepository(capturing.dio);

      final breeder = await repo.syncBreeder(
        name: 'João',
        city: 'Uberaba',
        state: 'MG',
        zipCode: '12345000',
      );

      expect(breeder.city, 'Uberaba');
      expect(breeder.state, 'MG');
    });
  });

  group('login', () {
    late MockAuth0 auth0;
    late MockWebAuthentication webAuth;

    setUp(() {
      auth0 = MockAuth0();
      webAuth = MockWebAuthentication();
      when(() => auth0.webAuthentication(scheme: any(named: 'scheme')))
          .thenReturn(webAuth);
    });

    test('returning user: syncs to the backend and returns the parsed '
        'Breeder', () async {
      when(() => webAuth.login(
            audience: any(named: 'audience'),
            scopes: any(named: 'scopes'),
          )).thenAnswer((_) async => _credentials());
      final repo = AuthRepository(
        _dioReturning(200, {
          'id': '1',
          'name': 'Fazenda X',
          'email': 'x@example.com',
        }),
        auth0: auth0,
      );

      final breeder = await repo.login();

      expect(breeder.id, '1');
      expect(breeder.name, 'Fazenda X');
    });

    test('no backend account yet (404/422): falls back to '
        '_breederFromCredentials built from the JWT', () async {
      for (final statusCode in [404, 422]) {
        when(() => webAuth.login(
              audience: any(named: 'audience'),
              scopes: any(named: 'scopes'),
            )).thenAnswer((_) async => _credentials(
              sub: 'auth0|123',
              email: 'x@example.com',
              name: 'Fazenda X',
            ));
        final repo = AuthRepository(
          _dioThrowing(DioExceptionType.badResponse, statusCode: statusCode),
          auth0: auth0,
        );

        final breeder = await repo.login();

        expect(breeder.id, 'auth0|123', reason: 'status $statusCode');
        expect(breeder.name, 'Fazenda X', reason: 'status $statusCode');
      }
    });

    test('any other backend error: rethrows rather than falling back',
        () async {
      when(() => webAuth.login(
            audience: any(named: 'audience'),
            scopes: any(named: 'scopes'),
          )).thenAnswer((_) async => _credentials());
      final repo = AuthRepository(
        _dioThrowing(DioExceptionType.badResponse, statusCode: 500),
        auth0: auth0,
      );

      expect(() => repo.login(), throwsA(isA<DioException>()));
    });
  });

  group('_breederFromCredentials (exercised via signUp, which never syncs)',
      () {
    late MockAuth0 auth0;
    late MockWebAuthentication webAuth;

    setUp(() {
      auth0 = MockAuth0();
      webAuth = MockWebAuthentication();
      when(() => auth0.webAuthentication(scheme: any(named: 'scheme')))
          .thenReturn(webAuth);
    });

    test('falls back through user.email ?? sub, and user.name ?? '
        'user.nickname ?? email', () async {
      when(() => webAuth.login(
            audience: any(named: 'audience'),
            scopes: any(named: 'scopes'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async => _credentials(
            sub: 'auth0|abc',
            email: 'x@example.com',
          ));
      final repo = AuthRepository(Dio(), auth0: auth0);

      final breeder = await repo.signUp();

      // email present -> used over sub; name/nickname both null -> falls
      // back to email.
      expect(breeder.email, 'x@example.com');
      expect(breeder.name, 'x@example.com');
    });

    test('no email at all: falls back to sub for both id and email',
        () async {
      when(() => webAuth.login(
            audience: any(named: 'audience'),
            scopes: any(named: 'scopes'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async => _credentials(sub: 'auth0|abc'));
      final repo = AuthRepository(Dio(), auth0: auth0);

      final breeder = await repo.signUp();

      expect(breeder.id, 'auth0|abc');
      expect(breeder.email, 'auth0|abc');
      expect(breeder.name, 'auth0|abc');
    });

    test('nickname used when name is absent but nickname is present',
        () async {
      when(() => webAuth.login(
            audience: any(named: 'audience'),
            scopes: any(named: 'scopes'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async => _credentials(
            sub: 'auth0|abc',
            email: 'x@example.com',
            nickname: 'joaozinho',
          ));
      final repo = AuthRepository(Dio(), auth0: auth0);

      final breeder = await repo.signUp();

      expect(breeder.name, 'joaozinho');
    });
  });

  group('restoreSession', () {
    late MockAuth0 auth0;
    late MockCredentialsManager credentialsManager;

    setUp(() {
      auth0 = MockAuth0();
      credentialsManager = MockCredentialsManager();
      when(() => auth0.credentialsManager).thenReturn(credentialsManager);
    });

    test('no stored/refreshable credentials: returns null (genuinely '
        'logged out)', () async {
      when(() => credentialsManager.credentials(
            minTtl: any(named: 'minTtl'),
            scopes: any(named: 'scopes'),
            parameters: any(named: 'parameters'),
          )).thenThrow(const CredentialsManagerException.unknown('no creds'));
      final repo = AuthRepository(Dio(), auth0: auth0);

      expect(await repo.restoreSession(), isNull);
    });

    test('valid credentials, backend sync succeeds: returns the parsed '
        'Breeder', () async {
      when(() => credentialsManager.credentials(
            minTtl: any(named: 'minTtl'),
            scopes: any(named: 'scopes'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async => _credentials());
      final repo = AuthRepository(
        _dioReturning(200, {
          'id': '1',
          'name': 'Fazenda X',
          'email': 'x@example.com',
        }),
        auth0: auth0,
      );

      final breeder = await repo.restoreSession();

      expect(breeder?.id, '1');
    });

    test('valid credentials, backend sync fails: falls back to '
        '_breederFromCredentials rather than forcing a re-login', () async {
      when(() => credentialsManager.credentials(
            minTtl: any(named: 'minTtl'),
            scopes: any(named: 'scopes'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async => _credentials(
            sub: 'auth0|abc',
            email: 'x@example.com',
            name: 'Fazenda X',
          ));
      final repo = AuthRepository(
        _dioThrowing(DioExceptionType.connectionError),
        auth0: auth0,
      );

      final breeder = await repo.restoreSession();

      expect(breeder?.id, 'auth0|abc');
      expect(breeder?.name, 'Fazenda X');
    });
  });

  group('logout', () {
    test('delegates to webAuthentication().logout()', () async {
      final auth0 = MockAuth0();
      final webAuth = MockWebAuthentication();
      when(() => auth0.webAuthentication(scheme: any(named: 'scheme')))
          .thenReturn(webAuth);
      when(() => webAuth.logout()).thenAnswer((_) async {});
      final repo = AuthRepository(Dio(), auth0: auth0);

      await repo.logout();

      verify(() => webAuth.logout()).called(1);
    });
  });

  group('getFreshToken', () {
    test('returns the access token on success', () async {
      final auth0 = MockAuth0();
      final credentialsManager = MockCredentialsManager();
      when(() => auth0.credentialsManager).thenReturn(credentialsManager);
      when(() => credentialsManager.credentials(
            minTtl: any(named: 'minTtl'),
            scopes: any(named: 'scopes'),
            parameters: any(named: 'parameters'),
          )).thenAnswer((_) async => _credentials());
      final repo = AuthRepository(Dio(), auth0: auth0);

      expect(await repo.getFreshToken(), 'access-token');
    });

    test('returns null on any credentials() failure', () async {
      final auth0 = MockAuth0();
      final credentialsManager = MockCredentialsManager();
      when(() => auth0.credentialsManager).thenReturn(credentialsManager);
      when(() => credentialsManager.credentials(
            minTtl: any(named: 'minTtl'),
            scopes: any(named: 'scopes'),
            parameters: any(named: 'parameters'),
          )).thenThrow(const CredentialsManagerException.unknown('boom'));
      final repo = AuthRepository(Dio(), auth0: auth0);

      expect(await repo.getFreshToken(), isNull);
    });
  });
}

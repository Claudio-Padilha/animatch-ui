import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:animatch/core/network/api_client.dart';
import 'package:animatch/core/network/api_exception.dart';
import 'package:animatch/features/auth/domain/breeder.dart';
import 'package:animatch/features/auth/providers/auth_provider.dart';

import '../helpers/fakes.dart';

void main() {
  // dioProvider builds its own Auth0 client internally (not
  // constructor-injectable — same limitation as AuthRepository before its
  // 2026-08-13 DI fix, but dioProvider itself hasn't been refactored). The
  // Auth0-success branch (attaches Authorization: Bearer <token>) is
  // therefore not unit-testable — flagged as a known gap per
  // docs/testing-plan.md §1.3, not attempted here.
  group('auth interceptor', () {
    test(
        'proceeds without an Authorization header when no credentials are '
        'stored (not logged in)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);
      final adapter = DioAdapter(dio: dio);
      RequestOptions? captured;
      adapter.onGet(
        '/ping',
        (server) => server.reply(200, {'ok': true}),
      );
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.next(options);
        },
      ));

      // credentialsManager.credentials() with no real platform channel
      // available under `flutter test` fails fast (no stored credentials
      // to find), which the interceptor's catch(_) treats the same as
      // "not logged in" — bounded timeout guards against this hanging
      // instead of failing fast, which would indicate this branch is
      // blocked after all.
      await dio.get<Map<String, dynamic>>('/ping').timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException(
              'auth interceptor hung waiting on credentials() — this '
              'branch may be blocked after all, see testing-plan.md §1.3',
            ),
          );

      expect(captured?.headers['Authorization'], isNull);
    });

    test('connectTimeout/receiveTimeout/sendTimeout match the configured '
        'BaseOptions (H-4 fix)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dio = container.read(dioProvider);

      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 30));
      expect(dio.options.sendTimeout, const Duration(seconds: 60));
    });
  });

  group('error interceptor (Item G)', () {
    const breeder = Breeder(id: 'b1', name: 'X', email: 'x@x.com');

    ProviderContainer makeContainer() {
      final c = ProviderContainer(overrides: [
        authNotifierProvider.overrideWith(() => SeededAuthNotifier(breeder)),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    test('403 (ownership) surfaces as ApiException and does NOT clear the '
        'session', () async {
      final container = makeContainer();
      final dio = container.read(dioProvider);
      DioAdapter(dio: dio).onGet(
        '/matches/m1',
        (server) => server.reply(403, {'message': 'Forbidden'}),
      );

      await expectLater(
        dio.get<dynamic>('/matches/m1'),
        throwsA(isA<DioException>().having(
          (e) => e.error, 'error', isA<ApiException>()
              .having((a) => a.isForbiddenResource, 'isForbiddenResource', true),
        )),
      );
      expect(container.read(authNotifierProvider), isNotNull);
    });

    test('404 surfaces as ApiException, session intact', () async {
      final container = makeContainer();
      final dio = container.read(dioProvider);
      DioAdapter(dio: dio).onGet(
        '/animals/x',
        (server) => server.reply(404, {'message': 'Not found'}),
      );

      await expectLater(
        dio.get<dynamic>('/animals/x'),
        throwsA(isA<DioException>()
            .having((e) => e.error, 'error', isA<ApiException>())),
      );
      expect(container.read(authNotifierProvider), isNotNull);
    });

    test('a 5xx passes straight through as a plain DioException', () async {
      final container = makeContainer();
      final dio = container.read(dioProvider);
      DioAdapter(dio: dio).onGet(
        '/animals',
        (server) => server.reply(500, {'message': 'boom'}),
      );

      await expectLater(
        dio.get<dynamic>('/animals'),
        throwsA(isA<DioException>()
            .having((e) => e.error, 'error', isNot(isA<ApiException>()))),
      );
    });
  });
}

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:animatch/core/services/device_token_service.dart';

void main() {
  group('register', () {
    test('POSTs token/platform to /breeders/device-token (no breederId)',
        () async {
      final dio = Dio(BaseOptions());
      final adapter = DioAdapter(dio: dio);
      // Platform.isIOS/isAndroid reflect the *host* OS running the test, not
      // a mockable value in a plain `flutter test` run — this will always
      // resolve to 'android' in this Linux CI environment. Asserting the
      // iOS branch would need Platform injected, which isn't currently
      // possible; documented as a known minor gap in docs/testing-plan.md
      // §1.5, not worth a refactor for one string.
      final expectedPlatform = Platform.isIOS ? 'ios' : 'android';
      adapter.onPost(
        '/breeders/device-token',
        (server) => server.reply(200, null),
        data: {
          'token': 'fcm-token',
          'platform': expectedPlatform,
        },
      );
      final service = DeviceTokenService(dio);

      await service.register('fcm-token');
      // No exception thrown means the exact payload matched.
    });
  });

  group('unregister', () {
    test('DELETEs the URL-encoded token path', () async {
      final dio = Dio(BaseOptions());
      final adapter = DioAdapter(dio: dio);
      adapter.onDelete(
        '/breeders/device-token/fcm%20token%2Fwith%2Fslashes',
        (server) => server.reply(200, null),
      );
      final service = DeviceTokenService(dio);

      await service.unregister('fcm token/with/slashes');
    });
  });
}

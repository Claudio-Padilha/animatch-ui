import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_env.dart';
import '../config/auth0_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  final auth0 = Auth0(Auth0Config.domain, Auth0Config.clientId);

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final credentials = await auth0.credentialsManager.credentials();
          options.headers['Authorization'] = 'Bearer ${credentials.accessToken}';
        } catch (_) {
          // Not logged in — request proceeds without auth header.
          // The backend will return 401 for protected routes.
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

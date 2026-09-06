import 'package:auth0_flutter/auth0_flutter.dart' hide ApiException;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_env.dart';
import '../config/auth0_config.dart';
import '../router/app_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'api_exception.dart';

/// Marks a request that has already been retried once after a 401 refresh, so
/// a still-failing token can't spin the interceptor forever.
const _retriedKey = 'auth_retried';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
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
      onError: (err, handler) async {
        final status = err.response?.statusCode;

        // 401 — no / expired / invalid token. Try one silent refresh, then
        // retry the request once; if that fails, the session is genuinely
        // gone, so clear it (the router redirects to login).
        if (status == 401 && err.requestOptions.extra[_retriedKey] != true) {
          try {
            final credentials = await auth0.credentialsManager.credentials();
            final retried = err.requestOptions
              ..extra[_retriedKey] = true
              ..headers['Authorization'] = 'Bearer ${credentials.accessToken}';
            final response = await dio.fetch<dynamic>(retried);
            return handler.resolve(response);
          } catch (_) {
            await _clearSession(ref, auth0);
            return handler.reject(
              DioException(
                requestOptions: err.requestOptions,
                error: ApiException(err),
                response: err.response,
                type: err.type,
              ),
            );
          }
        }

        if (status == 401 || status == 403 || status == 404) {
          final apiError = ApiException(err);

          if (status == 401) {
            await _clearSession(ref, auth0);
          } else if (apiError.needsProfile) {
            // Valid token, backend has no breeder profile — send them to
            // finish onboarding rather than showing an error.
            ref.read(routerProvider).go(AppRoutes.profileCompletion);
          }

          return handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: apiError,
              response: err.response,
              type: err.type,
            ),
          );
        }

        handler.next(err);
      },
    ),
  );

  return dio;
});

Future<void> _clearSession(Ref ref, Auth0 auth0) async {
  try {
    await auth0.credentialsManager.clearCredentials();
  } catch (_) {
    // Nothing stored / plugin unavailable — clearing state below is enough.
  }
  try {
    ref.read(authNotifierProvider.notifier).clearSession();
  } catch (e) {
    if (kDebugMode) debugPrint('[auth] clearSession failed: $e');
  }
}

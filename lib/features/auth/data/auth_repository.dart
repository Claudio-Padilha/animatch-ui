import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth0_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/breeder.dart';

class AuthRepository {
  AuthRepository(this._dio)
      : _auth0 = Auth0(Auth0Config.domain, Auth0Config.clientId);

  final Dio _dio;
  final Auth0 _auth0;

  Future<Breeder> login() async {
    final credentials = await _auth0
        .webAuthentication(scheme: Auth0Config.scheme)
        .login(
          audience: Auth0Config.audience,
          scopes: {'openid', 'profile', 'email', 'offline_access'},
        );
    try {
      // Returning user — fetch existing profile (empty body, sub comes from JWT).
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/sync-breeder',
        data: <String, dynamic>{},
      );
      return Breeder.fromJson(response.data!);
    } on DioException catch (e) {
      // No backend account yet — let profile completion create it.
      if (e.response?.statusCode == 422 || e.response?.statusCode == 404) {
        return _breederFromCredentials(credentials);
      }
      rethrow;
    }
  }

  Future<Breeder> signUp() async {
    final credentials = await _auth0
        .webAuthentication(scheme: Auth0Config.scheme)
        .login(
          audience: Auth0Config.audience,
          scopes: {'openid', 'profile', 'email', 'offline_access'},
          parameters: {'screen_hint': 'signup', 'prompt': 'login'},
        );
    // Don't sync to backend yet — profile completion handles that.
    return _breederFromCredentials(credentials);
  }

  Future<Breeder> syncBreeder({
    required String name,
    required String city,
    required String state,
    required String zipCode,
    String? directions,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/sync-breeder',
      data: {
        'name': name,
        'address': {
          'city': city,
          'state': state,
          'zipCode': zipCode,
          if (directions != null && directions.isNotEmpty)
            'directions': directions,
        },
      },
    );
    final breeder = Breeder.fromJson(response.data!);
    // Merge city/state from form in case the response omits them.
    return breeder.city != null
        ? breeder
        : breeder.copyWith(city: city, state: state);
  }

  // Restores a previous session silently using stored Auth0 credentials.
  // Returns null if no valid credentials exist (user needs to log in).
  Future<Breeder?> restoreSession() async {
    try {
      final hasCredentials =
          await _auth0.credentialsManager.hasValidCredentials();
      if (!hasCredentials) return null;
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/sync-breeder',
        data: <String, dynamic>{},
      );
      return Breeder.fromJson(response.data!);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _auth0.webAuthentication(scheme: Auth0Config.scheme).logout();
  }

  Future<String?> getFreshToken() async {
    try {
      final credentials = await _auth0.credentialsManager.credentials();
      return credentials.accessToken;
    } catch (_) {
      return null;
    }
  }

  Breeder _breederFromCredentials(Credentials credentials) {
    final sub = credentials.user.sub;
    final email = credentials.user.email ?? sub;
    final name = credentials.user.name ?? credentials.user.nickname ?? email;
    return Breeder(id: sub, name: name, email: email);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);

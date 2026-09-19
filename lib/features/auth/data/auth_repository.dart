import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/auth0_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/breeder.dart';

class AuthRepository {
  AuthRepository(this._dio, {Auth0? auth0})
      : _auth0 = auth0 ?? Auth0(Auth0Config.domain, Auth0Config.clientId);

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
    final Credentials credentials;
    try {
      credentials = await _auth0.credentialsManager.credentials();
    } on CredentialsManagerException {
      // No stored credentials, or refresh failed — genuinely logged out.
      return null;
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/sync-breeder',
        data: <String, dynamic>{},
      );
      return Breeder.fromJson(response.data!);
    } catch (_) {
      // Auth0 credentials are valid, but the backend sync failed (offline,
      // 5xx, unparseable response, ...). Don't force a re-login for what's
      // a transient backend problem — fall back to a minimal profile built
      // from the JWT, same as the "no backend account yet" path in login().
      return _breederFromCredentials(credentials);
    }
  }

  // Re-fetches the breeder profile for an already-logged-in user (e.g. on
  // app foreground) so server-side changes — like an admin revoking
  // verification — are picked up without requiring a full restart.
  // Returns null on failure, leaving the caller's cached profile as-is
  // rather than treating a transient error as a sign-out.
  Future<Breeder?> refreshBreeder() async {
    try {
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

  // Deletes the breeder's Animatch account and data (backend-side cascade).
  // The Auth0 identity itself is untouched — the API can't revoke a
  // stateless JWT — so we clear the locally stored credentials ourselves
  // to end the session client-side. Logging back in afterwards creates a
  // fresh profile rather than restoring this one.
  Future<void> deleteAccount(String breederId) async {
    await _dio.delete<void>('/breeders/$breederId');
    try {
      await _auth0.credentialsManager.clearCredentials();
    } catch (_) {
      // Nothing stored / plugin unavailable — clearing notifier state
      // (done by the caller) is enough to end the session either way.
    }
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

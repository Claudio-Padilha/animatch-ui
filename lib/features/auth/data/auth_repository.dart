import 'package:dio/dio.dart';

import '../../../core/auth/dev_token_service.dart';
import '../domain/breeder.dart';

// ── Internal DTO ─────────────────────────────────────────────────────────────

class _Auth0Result {
  const _Auth0Result({
    required this.sub,
    required this.email,
    required this.name,
    required this.accessToken,
  });

  final String sub;
  final String email;
  final String name;
  final String accessToken;
  // TODO: add picture (Uri?) when wiring real auth0_flutter
}

// ── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  // TODO: replace with real auth0_flutter webAuthentication().login() + /auth/sync
  Future<Breeder> login({required String email, String? name}) async {
    final sub = 'auth0|dev-${email.hashCode.abs()}';
    final credentials = _Auth0Result(
      sub: sub,
      email: email,
      name: name ?? email,
      accessToken: DevTokenService.buildFromCredentials(
          sub: sub, email: email, name: name ?? email),
    );
    return _syncWithBackend(credentials, sendName: name != null);
  }

  Future<Breeder> signUp({required String name, required String email}) async {
    final credentials = await _mockAuth0SignUp(name: name, email: email);
    return _syncWithBackend(credentials);
  }

  // ── Mock Auth0 ─────────────────────────────────────────────────────────────
  // TODO: replace with real auth0_flutter webAuthentication().login() call
  //       once Auth0 tenant and credentials are configured.
  //
  // For signup, pass parameters: {'screen_hint': 'signup'}
  // Scheme (Android/iOS): 'com.animatch.animatch'

  static Future<_Auth0Result> _mockAuth0SignUp({
    required String name,
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final sub = 'auth0|dev-${email.hashCode.abs()}';
    return _Auth0Result(
      sub: sub,
      email: email,
      name: name,
      accessToken: DevTokenService.buildFromCredentials(
          sub: sub, email: email, name: name),
    );
  }

  // ── Backend sync ───────────────────────────────────────────────────────────
  // POST /auth/sync
  // Creates or updates the breeder record on the Animatch backend.
  // In production the backend verifies the Auth0 access token before syncing.

  Future<Breeder> _syncWithBackend(
    _Auth0Result credentials, {
    bool sendName = true,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/sync-breeder',
      data: {
        'sub': credentials.sub,
        'email': credentials.email,
        if (sendName) 'name': credentials.name,
      },
      options: Options(
        headers: {'Authorization': 'Bearer ${credentials.accessToken}'},
      ),
    );
    return Breeder.fromJson(response.data!);
  }
}

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
}

// ── Repository ────────────────────────────────────────────────────────────────

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  // DEV-ONLY login flow.
  // Derives a stable sub from the email and calls /auth/sync-breeder without
  // a name field so the backend treats it as a lookup (not a create).
  //
  // REPLACE with real Auth0 when integrating:
  //   final credentials = await Auth0().webAuthentication().login();
  //   return _syncWithBackend(_Auth0Result.fromCredentials(credentials));
  Future<Breeder> login({required String email, String? name}) async {
    final sub = DevTokenService.subFromEmail(email);
    final credentials = _Auth0Result(
      sub: sub,
      email: email,
      name: name ?? email,
      accessToken: DevTokenService.buildFromCredentials(
          sub: sub, email: email, name: name ?? email),
    );
    return _syncWithBackend(credentials, sendName: name != null);
  }

  // DEV-ONLY register flow.
  //
  // REPLACE with real Auth0 when integrating:
  //   final credentials = await Auth0()
  //       .webAuthentication()
  //       .login(parameters: {'screen_hint': 'signup'});
  //   return _syncWithBackend(_Auth0Result.fromCredentials(credentials));
  Future<Breeder> signUp({required String name, required String email}) async {
    final credentials = await _mockAuth0SignUp(name: name, email: email);
    return _syncWithBackend(credentials);
  }

  // ── Mock Auth0 ─────────────────────────────────────────────────────────────
  // Simulates the Auth0 webAuthentication flow locally.
  // App scheme for real Auth0 redirect: 'com.animatch.animatch'
  // DELETE this method when Auth0 is wired up.

  static Future<_Auth0Result> _mockAuth0SignUp({
    required String name,
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final sub = DevTokenService.subFromEmail(email);
    return _Auth0Result(
      sub: sub,
      email: email,
      name: name,
      accessToken: DevTokenService.buildFromCredentials(
          sub: sub, email: email, name: name),
    );
  }

  // ── Backend sync ───────────────────────────────────────────────────────────
  // POST /auth/sync-breeder
  // Creates or updates the breeder record on the backend.
  // sendName=true  → upsert  (register)
  // sendName=false → lookup  (login — backend should 404 if not found)
  //
  // In production the backend verifies the Auth0 access token signature
  // before syncing. The dev stub token is accepted only in non-prod envs.

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

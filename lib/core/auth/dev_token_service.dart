import 'dart:convert';

import '../../features/auth/domain/breeder.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DEV-ONLY mock auth service.
//
// Purpose: lets the app talk to the backend without a real Auth0 tenant.
// The backend accepts these tokens in non-production environments because it
// skips signature verification when the Auth0 domain is not configured.
//
// REMOVE THIS ENTIRE CLASS when wiring real Auth0:
//   - Replace buildToken()          → use the access_token from auth0_flutter
//   - Replace subFromEmail()        → sub comes from Auth0's ID token, not us
//   - Replace buildFromCredentials()→ not needed; Auth0 provides the token
//
// Real Auth0 integration steps (kept here for reference):
//   1. Add auth0_flutter to pubspec.yaml
//   2. Configure Auth0 tenant (domain + clientId) in app_env.dart
//   3. Call Auth0().webAuthentication().login() on login/register
//   4. Use credentials.accessToken for all API requests
//   5. Pass credentials.idToken.sub to /auth/sync-breeder
// ─────────────────────────────────────────────────────────────────────────────
abstract final class DevTokenService {
  static String buildToken(Breeder breeder) => _build(
        sub: subFromEmail(breeder.email),
        email: breeder.email,
        name: breeder.name,
      );

  // Derives a stable, platform-independent sub from an email address.
  // Uses base64url(utf8(email)) so the result is identical on web (dart2js),
  // Android and iOS (native Dart VM) — unlike email.hashCode which differs
  // across platforms and Dart versions.
  //
  // REPLACE with the real `sub` from the Auth0 ID token when integrating Auth0.
  static String subFromEmail(String email) {
    final encoded = base64Url
        .encode(utf8.encode(email.toLowerCase().trim()))
        .replaceAll('=', '');
    return 'auth0|dev-$encoded';
  }

  static String buildFromCredentials({
    required String sub,
    required String email,
    required String name,
  }) =>
      _build(sub: sub, email: email, name: name);

  static String _build({
    required String sub,
    required String email,
    required String name,
  }) {
    const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
    final payloadBytes = utf8.encode(
      jsonEncode({'sub': sub, 'email': email, 'name': name}),
    );
    final payload = base64Url.encode(payloadBytes).replaceAll('=', '');
    const sig = 'ZGV2LXN0dWItc2VjcmV0'; // base64("dev-stub-secret")
    return '$header.$payload.$sig';
  }
}

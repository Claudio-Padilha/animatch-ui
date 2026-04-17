import 'dart:convert';

import '../../features/auth/domain/breeder.dart';

// Builds a mock JWT from a Breeder.
// Valid structure, stub signature — backend skips verification in local dev.
// TODO: remove when real Auth0 tokens are in use.
abstract final class DevTokenService {
  static String buildToken(Breeder breeder) => _build(
        sub: 'auth0|dev-${breeder.email.hashCode.abs()}',
        email: breeder.email,
        name: breeder.name,
      );

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

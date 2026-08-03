abstract final class Auth0Config {
  static const domain = String.fromEnvironment('AUTH0_DOMAIN');
  static const clientId = String.fromEnvironment('AUTH0_CLIENT_ID');
  static const audience = String.fromEnvironment('AUTH0_AUDIENCE');
  static const scheme = 'com.animatch.animatch';
}

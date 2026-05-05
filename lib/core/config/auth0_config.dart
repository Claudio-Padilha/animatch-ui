abstract final class Auth0Config {
  static const domain = String.fromEnvironment(
    'AUTH0_DOMAIN',
    defaultValue: 'dev-akrxwodm47ylsucp.us.auth0.com',
  );
  static const clientId = String.fromEnvironment(
    'AUTH0_CLIENT_ID',
    defaultValue: 'NZ6SL0brELjh8JqbsVG5ROfT1ujt9dYN',
  );
  static const audience = String.fromEnvironment(
    'AUTH0_AUDIENCE',
    defaultValue: 'https://api.animatch.com.br',
  );
  static const scheme = 'com.animatch.animatch';
}

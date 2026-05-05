# Auth0 Integration Plan

Replace the dev-stub token system with real Auth0 authentication.
The mock (`DevTokenService`, `_mockAuth0SignUp`) is removed entirely.
The backend contract (`/auth/sync-breeder`) stays unchanged.

---

## Phase 0 — Auth0 Tenant Setup (console, no code)

1. Create a free Auth0 account at auth0.com
2. **Create a Native application** (not SPA — Flutter uses system browser / PKCE)
   - Name: `Animatch Mobile`
   - Copy **Domain** and **Client ID** — needed in Phase 2
3. **Allowed Callback URLs**
   ```
   com.animatch.animatch://login-callback
   ```
   Add for both Android and iOS (same scheme).
4. **Allowed Logout URLs**
   ```
   com.animatch.animatch://logout-callback
   ```
5. **Connections** — enable:
   - Username-Password-Authentication (database)
   - Google (optional — just toggle on, no extra config on free tier)
6. **Branding** — optional; on free tier the login page shows Auth0's domain.

---

## Phase 1 — Flutter Package

Add to `pubspec.yaml`:

```yaml
dependencies:
  auth0_flutter: ^1.4.0   # check for latest
```

Remove from `pubspec.yaml` when done:
- `firebase_auth` (was only used for the phone OTP stub)

Run:
```bash
flutter pub get
```

---

## Phase 2 — App Config

### 2a. Create `lib/core/config/auth0_config.dart`

```dart
abstract final class Auth0Config {
  static const domain   = 'YOUR_TENANT.auth0.com';
  static const clientId = 'YOUR_CLIENT_ID';
  static const scheme   = 'com.animatch.animatch';
}
```

> For production, load `domain` and `clientId` from `--dart-define` env vars
> so they are not hard-coded in the binary.

### 2b. Android — `android/app/build.gradle.kts`

Add the manifest placeholder so the Auth0 SDK can register the callback intent filter:

```kotlin
android {
    defaultConfig {
        manifestPlaceholders["auth0Domain"] = "YOUR_TENANT.auth0.com"
        manifestPlaceholders["auth0Scheme"] = "com.animatch.animatch"
    }
}
```

### 2c. iOS — `ios/Runner/Info.plist`

Add URL scheme for the callback (requires macOS/Xcode):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.animatch.animatch</string>
    </array>
  </dict>
</array>
```

---

## Phase 3 — Auth Repository

Replace `lib/features/auth/data/auth_repository.dart`.

Key changes:
- Remove `_Auth0Result`, `_mockAuth0SignUp`, `buildFromCredentials` references
- `login()` and `signUp()` both call `Auth0(domain, clientId).webAuthentication().login()`
  - `signUp()` adds `parameters: {'screen_hint': 'signup'}` to land on the registration form
- `sub` comes from `credentials.user.sub` (ID token claim)
- `accessToken` comes from `credentials.accessToken`
- Pass both to `_syncWithBackend()` unchanged

```dart
import 'package:auth0_flutter/auth0_flutter.dart';
import '../../../core/config/auth0_config.dart';
import '../domain/breeder.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  const AuthRepository(this._dio);
  final Dio _dio;

  final _auth0 = Auth0(Auth0Config.domain, Auth0Config.clientId);

  Future<Breeder> login() async {
    final credentials = await _auth0
        .webAuthentication(scheme: Auth0Config.scheme)
        .login();
    return _syncWithBackend(credentials);
  }

  Future<Breeder> signUp() async {
    final credentials = await _auth0
        .webAuthentication(scheme: Auth0Config.scheme)
        .login(parameters: {'screen_hint': 'signup'});
    return _syncWithBackend(credentials);
  }

  Future<void> logout(String? refreshToken) async {
    await _auth0
        .webAuthentication(scheme: Auth0Config.scheme)
        .logout();
  }

  Future<Breeder> _syncWithBackend(Credentials credentials) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/sync-breeder',
      data: {
        'sub':   credentials.user.sub,
        'email': credentials.user.email,
        'name':  credentials.user.name,
      },
      options: Options(
        headers: {'Authorization': 'Bearer ${credentials.accessToken}'},
      ),
    );
    return Breeder.fromJson(response.data!);
  }
}
```

---

## Phase 4 — Auth Notifier

Update `lib/features/auth/providers/auth_provider.dart`.

Key changes:
- `login()` takes no parameters — Auth0 UI handles email/password
- `signUp()` takes no parameters — Auth0 UI handles the form
- Both set `state` and the access token on success
- `logout()` calls `_repository.logout()` before clearing state
- Remove `DevTokenService` import entirely

```dart
Future<void> login() async {
  final breeder = await _repository.login();
  ref.read(accessTokenProvider.notifier).set(breeder.accessToken); // see note
  state = breeder;
}

Future<void> signUp() async {
  final breeder = await _repository.signUp();
  ref.read(accessTokenProvider.notifier).set(breeder.accessToken);
  state = breeder;
}

Future<void> logout() async {
  await _repository.logout(/* refreshToken */);
  ref.read(accessTokenProvider.notifier).set(null);
  state = null;
}
```

> **Note on access token storage:** `_syncWithBackend` returns a `Breeder`.
> The `Breeder` model does not carry the access token today.
> Options:
> a) Store the Auth0 `accessToken` in a separate `credentialsProvider` (recommended — tokens rotate)
> b) Persist credentials via `auth0_flutter`'s built-in `CredentialsManager` (handles silent refresh automatically)

**Recommended:** use `Auth0.credentialsManager` for token storage and silent refresh:
```dart
// Get a fresh token before each API call
final credentials = await _auth0.credentialsManager.credentials();
// Use credentials.accessToken in the Dio interceptor
```
This means `accessTokenProvider` becomes a thin wrapper that calls `credentialsManager.credentials()` instead of holding a raw string.

---

## Phase 5 — UI Screens

### Login screen (`lib/features/auth/ui/login_screen.dart`)
- Remove email/password fields
- Single "Entrar" button calls `ref.read(authNotifierProvider.notifier).login()`
- Auth0 Universal Login handles the form in the system browser

### Register screen (`lib/features/auth/ui/register_screen.dart`)
- Remove all form fields (name, email, phone, password)
- Single "Criar conta" button calls `ref.read(authNotifierProvider.notifier).signUp()`
- Phone number collection: add a profile-completion step **after** Auth0 returns,
  or collect it in the `/auth/sync-breeder` post-login flow if the backend needs it at registration time

### Phone verification screen
- Delete `lib/features/auth/ui/phone_verification_screen.dart`
- Remove the `phoneVerification` route from `app_router.dart`

---

## Phase 6 — Remove Dev Stubs

Files to delete:
- `lib/core/auth/dev_token_service.dart`

Files to clean up:
- `lib/features/auth/data/auth_repository.dart` — remove `_Auth0Result`, `_mockAuth0SignUp`
- `lib/features/auth/providers/auth_provider.dart` — remove `DevTokenService` import
- `pubspec.yaml` — remove `firebase_auth`
- `lib/firebase_options.dart` — remove iOS/Android stubs if no longer needed for FCM

> `firebase_core` and `firebase_messaging` stay — still needed for FCM push notifications.

---

## Phase 7 — Backend

The backend already validates Auth0 JWTs at `/auth/sync-breeder`.
Verify the following env vars are set on the server for production:

```
AUTH0_DOMAIN=YOUR_TENANT.auth0.com
AUTH0_AUDIENCE=https://api.animatch.com.br   # or whatever audience is configured
```

The backend should reject tokens whose `sub` does not start with `auth0|` once dev mode is disabled.

---

## Token Refresh

Auth0 issues short-lived access tokens (~24h by default, configurable).
`auth0_flutter`'s `CredentialsManager.credentials()` silently refreshes using the
stored refresh token before expiry — no manual handling needed as long as
**Offline Access** scope is requested at login:

```dart
.login(scopes: {'openid', 'profile', 'email', 'offline_access'})
```

---

## Testing

| Scenario | How to test |
|---|---|
| Login happy path | Real Auth0 tenant + test account |
| Sign-up | Auth0 Universal Login with `screen_hint: signup` |
| Token refresh | Set short token lifetime in Auth0 dashboard (debug only) |
| Logout | Verify `credentialsManager.credentials()` throws after logout |
| Android callback | `adb logcat` — look for `com.animatch.animatch://login-callback` |
| iOS callback | Xcode console; test on simulator with test account |

---

## File Change Summary

| File | Action |
|---|---|
| `pubspec.yaml` | Add `auth0_flutter`, remove `firebase_auth` |
| `lib/core/config/auth0_config.dart` | **Create** |
| `lib/core/auth/dev_token_service.dart` | **Delete** |
| `lib/features/auth/data/auth_repository.dart` | Rewrite |
| `lib/features/auth/providers/auth_provider.dart` | Update |
| `lib/features/auth/ui/login_screen.dart` | Simplify |
| `lib/features/auth/ui/register_screen.dart` | Simplify |
| `lib/features/auth/ui/phone_verification_screen.dart` | Delete |
| `lib/core/router/app_router.dart` | Remove phone verification route |
| `lib/core/network/api_client.dart` | Update token source (credentialsManager) |
| `android/app/build.gradle.kts` | Add `auth0Domain` / `auth0Scheme` placeholders |
| `ios/Runner/Info.plist` | Add callback URL scheme |
